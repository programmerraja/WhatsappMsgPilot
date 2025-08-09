We want to build whatsapp message schdeuler where user open this app and see there contacts and click the contacts and have option to schdeule a the message wherer user can enter the message and schdeule the message for the future.

The app need to have background service in Kotlin


some sample code for the background service


Build app where i can enter mesage and sender phone number where the app need to send message on whatsapp automatically


```
// Launch WhatsApp with pre-filled message
void sendWhatsAppMessage(String phone, String message) async {
  var whatsappUrl = Uri.parse(
    "whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}"
  );
  if (await canLaunchUrl(whatsappUrl)) {
    await launchUrl(whatsappUrl);
  } else {
    // Handle error: WhatsApp not installed
  }
}


<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

```


```
List<AccessibilityNodeInfo> sendButtonNodes = rootInActiveWindow.findAccessibilityNodeInfosByViewId("com.whatsapp:id/send");
if (sendButtonNodes != null && !sendButtonNodes.isEmpty()) {
    AccessibilityNodeInfo sendButton = sendButtonNodes.get(0);
    if (sendButton.isVisibleToUser()) {
        sendButton.performAction(AccessibilityNodeInfo.ACTION_CLICK);
    }
}

```