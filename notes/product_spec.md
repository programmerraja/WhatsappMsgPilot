
**Product Name:**
**WhatsApp Auto Scheduler** (Personal Use Only)

### **Purpose**

Allow the user to schedule WhatsApp messages that are automatically sent at a chosen time, with the ability to view, edit, and delete pending messages.


### **User Features**

1. **Add New Schedule**

   * Select contact from WhatsApp contacts OR enter phone number manually.
   * Type a message.
   * Choose a date & time.
   * Save schedule.

2. **View Scheduled Messages**

   * List of all pending scheduled messages.
   * Each entry shows:

     * Contact name / phone
     * Message preview
     * Scheduled time

3. **Edit Scheduled Message**

   * Tap a scheduled item → edit message text, contact, or scheduled time.
   * Reschedule updates the background job.

4. **Delete Scheduled Message**

   * Swipe or tap delete → removes from storage & cancels background job.

5. **Automatic Sending**

   * At scheduled time:

     * Opens WhatsApp with the message.
     * AccessibilityService clicks send automatically.

6. **Settings**

   * Toggle Auto-Send On/Off
   * Button to open Accessibility Service settings to enable it.


### **UI Flow**

#### **Home Screen**

```
[ + New Schedule ]
--------------------------------------
10:30 AM | John Doe
"Happy Birthday!"
(Edit)  (Delete)
--------------------------------------
5:00 PM  | +91 9876543210
"Meeting at 6"
(Edit)  (Delete)
```

#### **New/Edit Schedule Screen**

```
Contact: [ Select Contact / Enter Phone ]
Message:
[ Hey, let's meet at 7 PM! ]
Date: [ 2025-08-10 ]  Time: [ 18:30 ]
[ Save Schedule ]
```

## Dev doc

### **Storage Design (Private File)**

Instead of a database, messages will be stored in a **JSON file** located in the app’s private storage (`path_provider`).

* **File path:**
  `/data/data/<package_name>/app_data/schedules.json`
* **Security:**

  * Only the app can read/write this file (Android sandbox).
  * No external apps can access it without root.

**JSON Structure:**

```json
[
  {
    "id": "uuid-string",
    "phone": "+911234567890",
    "message": "Happy Birthday!",
    "scheduled_time": 1723180200000,
    "status": "pending",
    "work_id": "workmanager-task-id"
  }
]
```

**Flutter File Operations:**

```dart
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

Future<File> _getFile() async {
  final dir = await getApplicationDocumentsDirectory();
  return File('${dir.path}/schedules.json');
}

Future<void> saveSchedules(List<Map<String, dynamic>> schedules) async {
  final file = await _getFile();
  await file.writeAsString(jsonEncode(schedules));
}

Future<List<Map<String, dynamic>>> loadSchedules() async {
  final file = await _getFile();
  if (!file.existsSync()) return [];
  final content = await file.readAsString();
  return List<Map<String, dynamic>>.from(jsonDecode(content));
}
```

---

### **Scheduling Package**

Use **workmanager** ([pub.dev link](https://pub.dev/packages/workmanager)) for Flutter background scheduling.

**Why workmanager?**

* Works even if app is closed.
* Can pass arguments (phone, message) to native Kotlin worker.
* Easy cancellation by unique name (used for edit/delete).

**Example:**

```dart
Workmanager().registerOneOffTask(
  "unique-task-id",
  "sendWhatsAppMessage",
  initialDelay: Duration(minutes: 5),
  inputData: {
    'phone': '+911234567890',
    'message': 'Hello from scheduler!'
  },
);
```

---

### **Edit/Delete Logic**

**Edit:**

1. Load schedules from file.
2. Update the selected item (message/phone/time).
3. Cancel old WorkManager task (`cancelByUniqueName`).
4. Schedule new task with updated details.
5. Save updated list to file.

**Delete:**

1. Load schedules from file.
2. Remove the selected item.
3. Cancel WorkManager task by ID.
4. Save updated list to file.

---

### **Native Kotlin Side**

1. **WorkManager Worker**

   * Reads phone & message from inputData.
   * Launches WhatsApp with pre-filled message.
2. **AccessibilityService**

   * Detects when WhatsApp is open.
   * Finds `com.whatsapp:id/send` and clicks it.

---

### **Permissions in AndroidManifest**

```xml
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

---

### **High-Level Code Flow**

```
Flutter UI
  → Save schedule to JSON
  → Schedule task via workmanager
  → Pass args to Kotlin Worker
      → Open WhatsApp with message
      → AccessibilityService auto-clicks send
```

---

### **Libraries Required**

**Flutter:**

* `workmanager` (task scheduling)
* `permission_handler` (ask user for Accessibility settings if needed)
* `path_provider` (get private file path)
* `uuid` (generate unique IDs for schedules)

**Kotlin:**

* `androidx.work:work-runtime-ktx` (WorkManager)
* `AccessibilityService` (auto send)

---

