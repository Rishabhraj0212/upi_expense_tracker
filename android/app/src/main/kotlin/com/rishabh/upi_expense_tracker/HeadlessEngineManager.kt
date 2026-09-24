package com.rishabh.upi_expense_tracker

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.view.FlutterCallbackInformation
import java.util.ArrayDeque

/**
 * Runs a background (UI-less) FlutterEngine to process a captured SMS/
 * notification event when nobody is live-listening on [SmsEventBridge] /
 * [NotificationEventBridge] — i.e. the app isn't currently running.
 *
 * Best-effort by design (see Milestone 8 discussion): no foreground service,
 * no persistent notification. Relies on the caller giving the process enough
 * time to finish (SmsReceiver uses goAsync(); NotificationListenerService's
 * own bound-service lifetime already covers it). One engine is reused for
 * everything queued while it's alive, then torn down once the queue drains.
 */
object HeadlessEngineManager {
    private const val CHANNEL = "upi_tracker/headless"
    private const val PREFS = "headless_prefs"
    private const val KEY_CALLBACK_HANDLE = "callback_handle"
    private const val TIMEOUT_MS = 15_000L

    private val mainHandler = Handler(Looper.getMainLooper())
    private val queue = ArrayDeque<Pair<Map<String, Any?>, () -> Unit>>()

    private var engine: FlutterEngine? = null
    private var channel: MethodChannel? = null
    private var ready = false
    private var processing = false

    /** Called once from the foreground app so we know which Dart entrypoint to run later. */
    fun saveCallbackHandle(context: Context, handle: Long) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putLong(KEY_CALLBACK_HANDLE, handle).apply()
    }

    /** [onDone] always fires exactly once — success, failure, or timeout. */
    fun enqueue(context: Context, payload: Map<String, Any?>, onDone: () -> Unit) {
        mainHandler.post {
            queue.add(payload to onDone)
            startIfNeeded(context.applicationContext)
        }
    }

    private fun startIfNeeded(context: Context) {
        if (engine != null) {
            if (ready) pumpQueue()
            return // still starting up; its own "ready" callback will pump the queue
        }

        val handle = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getLong(KEY_CALLBACK_HANDLE, -1L)
        if (handle == -1L) {
            // The app has never run in the foreground yet to register the
            // callback handle, so there's no known entrypoint to execute.
            drainQueue()
            return
        }
        val callbackInfo = FlutterCallbackInformation.lookupCallbackInformation(handle)
        if (callbackInfo == null) {
            drainQueue()
            return
        }

        val loader = FlutterInjector.instance().flutterLoader()
        if (!loader.initialized()) loader.startInitialization(context)
        loader.ensureInitializationComplete(context, null)

        val newEngine = FlutterEngine(context)
        GeneratedPluginRegistrant.registerWith(newEngine)
        val newChannel = MethodChannel(newEngine.dartExecutor.binaryMessenger, CHANNEL)
        engine = newEngine
        channel = newChannel

        newChannel.setMethodCallHandler { call, result ->
            if (call.method == "ready") {
                ready = true
                result.success(null)
                pumpQueue()
            } else {
                result.notImplemented()
            }
        }

        newEngine.dartExecutor.executeDartCallback(
            DartExecutor.DartCallback(context.assets, loader.findAppBundlePath(), callbackInfo)
        )

        // Safety net: if Dart never signals "ready" (crash, cold start too
        // slow), tear down and fail the queue rather than leak the engine.
        val startedEngine = newEngine
        mainHandler.postDelayed({
            if (engine === startedEngine && !ready) teardown(failQueue = true)
        }, TIMEOUT_MS)
    }

    private fun pumpQueue() {
        val ch = channel ?: return
        if (processing) return
        val next = queue.poll()
        if (next == null) {
            teardown(failQueue = false)
            return
        }
        processing = true
        ch.invokeMethod("ingest", next.first, object : MethodChannel.Result {
            override fun success(result: Any?) = finishOne(next.second)
            override fun error(code: String, msg: String?, details: Any?) = finishOne(next.second)
            override fun notImplemented() = finishOne(next.second)
        })
    }

    private fun finishOne(onDone: () -> Unit) {
        processing = false
        onDone()
        pumpQueue()
    }

    private fun drainQueue() {
        while (true) {
            val item = queue.poll() ?: break
            item.second()
        }
    }

    private fun teardown(failQueue: Boolean) {
        if (failQueue) drainQueue()
        engine?.destroy()
        engine = null
        channel = null
        ready = false
        processing = false
    }
}
