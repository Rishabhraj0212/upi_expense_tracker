package com.rishabh.upi_expense_tracker

import android.content.Intent
import android.content.IntentSender
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import androidx.core.app.NotificationManagerCompat
import com.google.android.gms.auth.api.identity.AuthorizationRequest
import com.google.android.gms.auth.api.identity.AuthorizationResult
import com.google.android.gms.auth.api.identity.Identity
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.common.api.Scope
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

/**
 * Business logic (parsing, dedup, storage, sync orchestration) lives in
 * Dart. This class exposes only what genuinely requires an Android API:
 * the Notification access / battery-optimization-exemption special
 * permission screens (neither covered by permission_handler), and — as of
 * Step 7 — `drive.file` authorization via Play Services' AuthorizationClient,
 * which is how Google's own native file picker is triggered for selecting
 * an existing spreadsheet. This is authorization only: it never touches
 * account sign-in (handled entirely in Dart via google_sign_in) and never
 * itself decides connection/sync state (also decided entirely in Dart).
 */
class MainActivity : FlutterActivity() {
    private var pendingAuthorizationResult: MethodChannel.Result? = null

    private val authorizationClient by lazy { Identity.getAuthorizationClient(this) }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PLATFORM_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isNotificationListenerEnabled" -> result.success(
                        packageName in NotificationManagerCompat.getEnabledListenerPackages(this)
                    )
                    "openNotificationListenerSettings" -> {
                        startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                        result.success(null)
                    }
                    "registerHeadlessCallbackHandle" -> {
                        val handle = call.argument<Number>("handle")?.toLong()
                        if (handle != null) HeadlessEngineManager.saveCallbackHandle(this, handle)
                        result.success(null)
                    }
                    "isIgnoringBatteryOptimizations" -> {
                        val pm = getSystemService(POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    }
                    "requestIgnoreBatteryOptimizations" -> {
                        startActivity(
                            Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                                .setData(Uri.parse("package:$packageName"))
                        )
                        result.success(null)
                    }
                    "getSmsInboxCount" -> {
                        val sinceMs = call.argument<Number>("sinceMs")?.toLong() ?: 0L
                        val untilMs = call.argument<Number>("untilMs")?.toLong()
                            ?: System.currentTimeMillis()
                        try {
                            val cursor = contentResolver.query(
                                android.provider.Telephony.Sms.Inbox.CONTENT_URI,
                                arrayOf("_id"),
                                "date >= ? AND date <= ?",
                                arrayOf(sinceMs.toString(), untilMs.toString()),
                                null,
                            )
                            val count = cursor?.count ?: 0
                            cursor?.close()
                            result.success(count)
                        } catch (e: SecurityException) {
                            result.error("permission_denied", "SMS permission not granted", null)
                        } catch (e: Exception) {
                            result.error("sms_query_failed", e.message, null)
                        }
                    }
                    "readSmsInbox" -> {
                        val sinceMs = call.argument<Number>("sinceMs")?.toLong() ?: 0L
                        val untilMs = call.argument<Number>("untilMs")?.toLong()
                            ?: System.currentTimeMillis()
                        val offset = call.argument<Number>("offset")?.toInt() ?: 0
                        val limit = call.argument<Number>("limit")?.toInt() ?: 100
                        try {
                            val messages = mutableListOf<Map<String, Any?>>()
                            val cursor = contentResolver.query(
                                android.provider.Telephony.Sms.Inbox.CONTENT_URI,
                                arrayOf("_id", "address", "body", "date"),
                                "date >= ? AND date <= ?",
                                arrayOf(sinceMs.toString(), untilMs.toString()),
                                "date ASC LIMIT $limit OFFSET $offset",
                            )
                            cursor?.use {
                                while (it.moveToNext()) {
                                    messages.add(
                                        mapOf(
                                            "id" to it.getLong(0),
                                            "address" to (it.getString(1) ?: ""),
                                            "body" to (it.getString(2) ?: ""),
                                            "dateMs" to it.getLong(3),
                                        )
                                    )
                                }
                            }
                            result.success(messages)
                        } catch (e: SecurityException) {
                            result.error("permission_denied", "SMS permission not granted", null)
                        } catch (e: Exception) {
                            result.error("sms_query_failed", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_EVENTS_CHANNEL)
            .setStreamHandler(SmsEventBridge)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_EVENTS_CHANNEL)
            .setStreamHandler(NotificationEventBridge)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DRIVE_AUTHORIZATION_CHANNEL)
            .setMethodCallHandler { call, result ->
                Log.d(TAG, "MethodChannel call received: ${call.method}")
                when (call.method) {
                    "authorizeDriveFile" -> {
                        val showPicker = call.argument<Boolean>("showPicker") ?: false
                        authorizeDriveFile(showPicker, result)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun authorizeDriveFile(showPicker: Boolean, result: MethodChannel.Result) {
        Log.d(TAG, "authorizeDriveFile: entry, showPicker=$showPicker")
        // Diagnostic only (temporary): this is exactly the package name +
        // certificate fingerprint Play Services checks against the
        // registered Android OAuth client — not a secret, safe to log.
        logSigningIdentity()
        if (pendingAuthorizationResult != null) {
            Log.d(TAG, "authorizeDriveFile: rejected, an authorization is already pending")
            result.error("busy", "An authorization request is already in progress.", null)
            return
        }
        pendingAuthorizationResult = result

        var requestBuilder = AuthorizationRequest.builder()
            .setRequestedScopes(listOf(Scope(DRIVE_FILE_SCOPE)))
            .setOptOutIncludingGrantedScopes(true)
        if (showPicker) {
            // Prompt.CONSENT and resource parameters go together: Google's
            // AuthorizationRequest.Builder docs specify CONSENT is honored
            // only for requests that include resource parameters (the
            // Picker trigger here) or that request an auth code — plain
            // token requests with no resource parameters (the create-only
            // path below) must not force it.
            requestBuilder = requestBuilder
                .setPrompt(AuthorizationRequest.Prompt.CONSENT)
                // Google's own native Picker UI, triggered as part of this
                // same authorization request — not a WebView/Custom Tab of
                // our own.
                .addResourceParameter(AuthorizationRequest.ResourceParameter.PICKER_OAUTH_TRIGGER, "true")
                .addResourceParameter(AuthorizationRequest.ResourceParameter.PICKER_MIMETYPES, SPREADSHEET_MIME_TYPE)
        }
        Log.d(
            TAG,
            "authorizeDriveFile: request built (scope=$DRIVE_FILE_SCOPE, optOutIncludingGrantedScopes=true, " +
                "prompt=${if (showPicker) "CONSENT" else "NOT_SET (no setPrompt() call made)"}, pickerTrigger=$showPicker)",
        )

        authorizationClient.authorize(requestBuilder.build())
            .addOnSuccessListener { authorizationResult ->
                Log.d(TAG, "authorizeDriveFile: authorize() succeeded, hasResolution=${authorizationResult.hasResolution()}")
                if (authorizationResult.hasResolution()) {
                    try {
                        startIntentSenderForResult(
                            authorizationResult.pendingIntent!!.intentSender,
                            AUTHORIZATION_REQUEST_CODE,
                            null,
                            0,
                            0,
                            0,
                            null,
                        )
                        Log.d(TAG, "authorizeDriveFile: startIntentSenderForResult launched")
                    } catch (e: IntentSender.SendIntentException) {
                        Log.e(TAG, "authorizeDriveFile: SendIntentException launching resolution", e)
                        finishAuthorizationWithError("launch_failed", e.message)
                    }
                } else {
                    Log.d(TAG, "authorizeDriveFile: no resolution needed, already authorized")
                    finishAuthorizationWithSuccess(authorizationResult)
                }
            }
            .addOnFailureListener { e ->
                Log.e(TAG, "authorizeDriveFile: authorize() failed: ${e.javaClass.simpleName}: ${e.message}", e)
                finishAuthorizationWithError("authorization_failed", e.message)
            }
    }

    // FlutterActivity extends plain android.app.Activity (not
    // androidx.activity.ComponentActivity), so the modern Activity Result
    // API isn't available here — this is the correct, supported way to
    // receive the PendingIntent launched above.
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != AUTHORIZATION_REQUEST_CODE) return
        Log.d(
            TAG,
            "onActivityResult: requestCode=$requestCode, resultCode=$resultCode (RESULT_OK=$RESULT_OK), " +
                "dataIsNull=${data == null}",
        )

        if (resultCode != RESULT_OK) {
            // A non-OK resultCode from the resolution Activity can still
            // carry a real, diagnosable authorization error in its Intent —
            // it is not necessarily a plain user cancellation. Inspect it
            // before assuming so.
            if (data != null) {
                try {
                    val authorizationResult = authorizationClient.getAuthorizationResultFromIntent(data)
                    Log.d(TAG, "onActivityResult: non-OK resultCode, but getAuthorizationResultFromIntent succeeded")
                    finishAuthorizationWithSuccess(authorizationResult)
                    return
                } catch (e: ApiException) {
                    Log.e(
                        TAG,
                        "onActivityResult: non-OK resultCode; getAuthorizationResultFromIntent threw ApiException " +
                            "statusCode=${e.statusCode}, statusMessage=${e.statusMessage}, message=${e.message}",
                        e,
                    )
                    finishAuthorizationWithError(
                        "authorization_failed",
                        "Authorization error ${e.statusCode}: ${e.statusMessage ?: e.message}",
                    )
                    return
                } catch (e: Exception) {
                    Log.e(
                        TAG,
                        "onActivityResult: non-OK resultCode; getAuthorizationResultFromIntent threw unexpected " +
                            "${e.javaClass.simpleName}: ${e.message}",
                        e,
                    )
                    // Fall through to plain cancellation below — this intent
                    // genuinely carried nothing diagnosable.
                }
            }
            Log.d(TAG, "onActivityResult: no diagnosable error in the Intent; treating as a user cancellation")
            pendingAuthorizationResult?.error("cancelled", "The user cancelled authorization.", null)
            pendingAuthorizationResult = null
            return
        }
        try {
            val authorizationResult = authorizationClient.getAuthorizationResultFromIntent(data)
            finishAuthorizationWithSuccess(authorizationResult)
        } catch (e: ApiException) {
            Log.e(TAG, "onActivityResult: ApiException statusCode=${e.statusCode}: ${e.message}", e)
            finishAuthorizationWithError("authorization_failed", e.message)
        }
    }

    /** Diagnostic only (temporary) — see the call site above. */
    private fun logSigningIdentity() {
        try {
            val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                val info = packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
                info.signingInfo?.apkContentsSigners
            } else {
                @Suppress("DEPRECATION")
                val info = packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
                @Suppress("DEPRECATION")
                info.signatures
            }
            val sha1 = signatures?.firstOrNull()?.let { signature ->
                MessageDigest.getInstance("SHA-1").digest(signature.toByteArray())
                    .joinToString(":") { "%02X".format(it) }
            }
            Log.d(TAG, "logSigningIdentity: packageName=$packageName, signingCertSha1=$sha1")
        } catch (e: Exception) {
            Log.e(TAG, "logSigningIdentity: failed to read signing certificate: ${e.message}", e)
        }
    }

    private fun finishAuthorizationWithSuccess(authorizationResult: AuthorizationResult) {
        // Never logged, never persisted here — handed straight to Dart,
        // which is responsible for keeping it memory-only too.
        val accessToken = authorizationResult.accessToken
        Log.d(TAG, "finishAuthorizationWithSuccess: hasAccessToken=${accessToken != null}")
        if (accessToken == null) {
            finishAuthorizationWithError("no_access_token", "No access token was returned.")
            return
        }
        val pickedFileId = authorizationResult.tokenResponseParams
            ?.getString("picked_file_ids")
            ?.split(",")
            ?.firstOrNull { it.isNotBlank() }
        Log.d(TAG, "finishAuthorizationWithSuccess: hasPickedFileId=${pickedFileId != null}")

        pendingAuthorizationResult?.success(mapOf("accessToken" to accessToken, "pickedFileId" to pickedFileId))
        pendingAuthorizationResult = null
    }

    private fun finishAuthorizationWithError(code: String, message: String?) {
        Log.d(TAG, "finishAuthorizationWithError: code=$code, message=$message")
        pendingAuthorizationResult?.error(code, message ?: "Authorization failed.", null)
        pendingAuthorizationResult = null
    }

    companion object {
        private const val PLATFORM_CHANNEL = "upi_tracker/platform"
        private const val SMS_EVENTS_CHANNEL = "upi_tracker/sms_events"
        private const val NOTIFICATION_EVENTS_CHANNEL = "upi_tracker/notification_events"
        private const val DRIVE_AUTHORIZATION_CHANNEL = "upi_tracker/drive_authorization"
        private const val DRIVE_FILE_SCOPE = "https://www.googleapis.com/auth/drive.file"
        private const val SPREADSHEET_MIME_TYPE = "application/vnd.google-apps.spreadsheet"
        private const val AUTHORIZATION_REQUEST_CODE = 9001
        private const val TAG = "SheetSync"
    }
}
