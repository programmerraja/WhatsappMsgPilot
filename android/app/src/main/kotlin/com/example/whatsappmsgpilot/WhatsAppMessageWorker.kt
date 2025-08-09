package com.example.whatsappmsgpilot

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import androidx.work.Worker
import androidx.work.WorkerParameters
import java.net.URLEncoder

class WhatsAppMessageWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    
    companion object {
        private const val TAG = "WhatsAppMessageWorker"
        private const val WHATSAPP_PACKAGE = "com.whatsapp"
    }

    override fun doWork(): Result {
        return try {
            val phone = inputData.getString("phone")
            val message = inputData.getString("message")
            val contactName = inputData.getString("contactName")
            val scheduleId = inputData.getString("scheduleId")

            Log.d(TAG, "Starting work for schedule: $scheduleId")
            Log.d(TAG, "Phone: $phone, Message: $message, Contact: $contactName")

            if (phone.isNullOrEmpty() || message.isNullOrEmpty()) {
                Log.e(TAG, "Phone or message is empty")
                return Result.failure()
            }

            // Launch WhatsApp with the message
            val success = launchWhatsAppWithMessage(phone, message)
            
            if (success) {
                Log.d(TAG, "Successfully launched WhatsApp")
                Result.success()
            } else {
                Log.e(TAG, "Failed to launch WhatsApp")
                Result.failure()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in doWork: ${e.message}", e)
            Result.failure()
        }
    }

    private fun launchWhatsAppWithMessage(phone: String, message: String): Boolean {
        return try {
            // Clean phone number (remove + and spaces)
            val cleanPhone = phone.replace("+", "").replace(" ", "").replace("-", "")
            
            // Encode the message for URL
            val encodedMessage = URLEncoder.encode(message, "UTF-8")
            
            // Create WhatsApp URL intent
            val whatsappIntent = Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse("https://api.whatsapp.com/send?phone=$cleanPhone&text=$encodedMessage")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }

            // Check if WhatsApp is installed
            val packageManager = applicationContext.packageManager
            val resolveInfo = packageManager.resolveActivity(whatsappIntent, 0)
            
            if (resolveInfo != null) {
                // Launch WhatsApp
                applicationContext.startActivity(whatsappIntent)
                Log.d(TAG, "WhatsApp intent launched successfully")
                
                // TODO: Here we would normally trigger the accessibility service
                // to automatically click the send button
                
                return true
            } else {
                Log.e(TAG, "WhatsApp is not installed")
                return false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error launching WhatsApp: ${e.message}", e)
            false
        }
    }

    private fun isWhatsAppInstalled(): Boolean {
        return try {
            applicationContext.packageManager.getPackageInfo(WHATSAPP_PACKAGE, 0)
            true
        } catch (e: Exception) {
            false
        }
    }
}