/// Android package name -> display name, for apps whose payment
/// notifications we parse. Add a new UPI app by adding one line here.
const Map<String, String> upiNotificationApps = {
  'com.google.android.apps.nbu.paisa.user': 'Google Pay',
  'com.phonepe.app': 'PhonePe',
  'net.one97.paytm': 'Paytm',
  'in.org.npci.upiapp': 'BHIM',
  'money.super.payments': 'super.money',
  'com.dreamplug.androidapp': 'CRED',
};
