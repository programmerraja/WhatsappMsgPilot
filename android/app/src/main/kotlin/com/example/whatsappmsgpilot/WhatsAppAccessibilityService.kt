package com.example.whatsappmsgpilot

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.SharedPreferences
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

class WhatsAppAccessibilityService : AccessibilityService() {
    
    companion object {
        private const val TAG = "WhatsAppAccessibility"
        private const val WHATSAPP_PACKAGE = "com.whatsapp"
        private const val SEND_BUTTON_ID = "com.whatsapp:id/send"
        private const val SEND_BUTTON_TEXT = "Send"
        private const val PREFS_NAME = "whatsapp_scheduler_prefs"
        private const val AUTO_SEND_ENABLED = "auto_send_enabled"
    }

    private lateinit var sharedPrefs: SharedPreferences
    private val handler = Handler(Looper.getMainLooper())

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "Accessibility Service Connected")
        
        sharedPrefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
        
        // Configure the service
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or 
                        AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS
            packageNames = arrayOf(WHATSAPP_PACKAGE)
        }
        
        serviceInfo = info
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        
        // Check if auto-send is enabled
        if (!isAutoSendEnabled()) {
            return
        }

        // Only process events from WhatsApp
        if (event.packageName != WHATSAPP_PACKAGE) {
            return
        }

        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED,
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                // Give WhatsApp time to load
                handler.postDelayed({
                    findAndClickSendButton()
                }, 2000) // 2 second delay
            }
        }
    }

    private fun isAutoSendEnabled(): Boolean {
        return sharedPrefs.getBoolean(AUTO_SEND_ENABLED, true)
    }

    private fun findAndClickSendButton() {
        val rootNode = rootInActiveWindow ?: return
        
        try {
            // First try to find by resource ID
            var sendButton = findNodeByResourceId(rootNode, SEND_BUTTON_ID)
            
            // If not found by ID, try to find by text
            if (sendButton == null) {
                sendButton = findNodeByText(rootNode, SEND_BUTTON_TEXT)
            }
            
            // If not found by text, try alternative approaches
            if (sendButton == null) {
                sendButton = findSendButtonAlternative(rootNode)
            }

            if (sendButton != null && sendButton.isClickable) {
                val clicked = sendButton.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                Log.d(TAG, "Send button click attempted: $clicked")
                
                if (clicked) {
                    Log.d(TAG, "Message sent successfully via accessibility service")
                } else {
                    Log.w(TAG, "Failed to click send button")
                }
            } else {
                Log.d(TAG, "Send button not found or not clickable")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error finding/clicking send button: ${e.message}", e)
        } finally {
            rootNode.recycle()
        }
    }

    private fun findNodeByResourceId(root: AccessibilityNodeInfo, resourceId: String): AccessibilityNodeInfo? {
        val nodes = root.findAccessibilityNodeInfosByViewId(resourceId)
        return if (nodes.isNotEmpty()) {
            nodes[0]
        } else null
    }

    private fun findNodeByText(root: AccessibilityNodeInfo, text: String): AccessibilityNodeInfo? {
        val nodes = root.findAccessibilityNodeInfosByText(text)
        for (node in nodes) {
            if (node.text?.toString()?.equals(text, ignoreCase = true) == true ||
                node.contentDescription?.toString()?.equals(text, ignoreCase = true) == true) {
                return node
            }
        }
        return null
    }

    private fun findSendButtonAlternative(root: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        // Look for nodes with send-related descriptions or classes
        return findNodeRecursively(root) { node ->
            val desc = node.contentDescription?.toString()?.lowercase()
            val text = node.text?.toString()?.lowercase()
            val className = node.className?.toString()?.lowercase()
            
            (desc?.contains("send") == true) ||
            (text?.contains("send") == true) ||
            (className?.contains("button") == true && 
             (desc?.isNotEmpty() == true || text?.isNotEmpty() == true))
        }
    }

    private fun findNodeRecursively(
        node: AccessibilityNodeInfo, 
        condition: (AccessibilityNodeInfo) -> Boolean
    ): AccessibilityNodeInfo? {
        if (condition(node)) {
            return node
        }
        
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            val result = findNodeRecursively(child, condition)
            if (result != null) {
                return result
            }
            child.recycle()
        }
        
        return null
    }

    override fun onInterrupt() {
        Log.d(TAG, "Accessibility Service Interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Accessibility Service Destroyed")
    }
}