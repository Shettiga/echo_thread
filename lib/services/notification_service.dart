import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static Map<String, dynamic>? _cachedConfig;

  /// Fetch configuration keys from Firestore collection: config, doc: notifications
  static Future<Map<String, dynamic>> _getConfig() async {
    if (_cachedConfig != null) return _cachedConfig!;
    try {
      final doc = await FirebaseFirestore.instance.collection('config').doc('notifications').get();
      if (doc.exists && doc.data() != null) {
        _cachedConfig = doc.data();
        debugPrint('[NOTIFICATION_SERVICE] Loaded configuration keys from Firestore.');
        return _cachedConfig!;
      }
    } catch (e) {
      debugPrint('[NOTIFICATION_SERVICE] Error loading config: $e');
    }
    return {};
  }

  /// Manually refresh the cached configuration (e.g. after editing settings)
  static void clearCache() {
    _cachedConfig = null;
  }

  /// Sends a real or simulated email notification.
  static Future<bool> sendEmail({
    required String email,
    required String name,
    required String activity, // 'Registration' or 'Login'
    required DateTime dateTime,
  }) async {
    final config = await _getConfig();
    final brevoApiKey = config['brevo_api_key'] as String?;
    final senderName = config['email_sender_name'] as String? ?? 'EchoThread Platform';
    final senderEmail = config['email_sender_email'] as String? ?? 'noreply@echothread.org';

    final timestampStr = dateTime.toLocal().toString().substring(0, 19);

    // HTML Email Template
    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>EchoThread Notification</title>
  <style>
    body {
      font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      background-color: #f4f7f5;
      margin: 0;
      padding: 0;
    }
    .container {
      max-width: 600px;
      margin: 40px auto;
      background-color: #ffffff;
      border-radius: 16px;
      overflow: hidden;
      box-shadow: 0 8px 24px rgba(0,0,0,0.06);
      border: 1px solid #e1e8e3;
    }
    .header {
      background: linear-gradient(135deg, #2e7d32, #43a047);
      padding: 30px 20px;
      text-align: center;
      color: #ffffff;
    }
    .header h1 {
      margin: 0;
      font-size: 26px;
      font-weight: 800;
      letter-spacing: 0.5px;
    }
    .content {
      padding: 40px 30px;
      color: #333333;
    }
    .content h2 {
      font-size: 20px;
      color: #2e7d32;
      margin-top: 0;
    }
    .details-table {
      width: 100%;
      margin: 24px 0;
      border-collapse: collapse;
    }
    .details-table td {
      padding: 12px 8px;
      border-bottom: 1px solid #eff3f0;
      font-size: 14px;
    }
    .details-table td.label {
      font-weight: bold;
      color: #555555;
      width: 30%;
    }
    .details-table td.value {
      color: #222222;
    }
    .footer {
      background-color: #f8faf9;
      padding: 20px;
      text-align: center;
      font-size: 12px;
      color: #777777;
      border-top: 1px solid #eff3f0;
    }
    .btn {
      display: inline-block;
      padding: 12px 24px;
      background-color: #2e7d32;
      color: #ffffff;
      text-decoration: none;
      border-radius: 8px;
      font-weight: bold;
      margin-top: 16px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>EchoThread</h1>
      <p style="margin: 5px 0 0 0; opacity: 0.9;">Connecting Donors, NGOs & Volunteers</p>
    </div>
    <div class="content">
      <h2>Activity Notification</h2>
      <p>Hello <strong>$name</strong>,</p>
      <p>This is a formal notification of a recent security/activity event on your EchoThread account:</p>
      
      <table class="details-table">
        <tr>
          <td class="label">User Name</td>
          <td class="value">$name</td>
        </tr>
        <tr>
          <td class="label">Email Address</td>
          <td class="value">$email</td>
        </tr>
        <tr>
          <td class="label">Activity</td>
          <td class="value"><span style="background-color: #e8f5e9; color: #2e7d32; padding: 4px 8px; border-radius: 4px; font-weight: bold;">$activity</span></td>
        </tr>
        <tr>
          <td class="label">Date & Time</td>
          <td class="value">$timestampStr</td>
        </tr>
      </table>
      
      <p>If you did not perform this action, please contact support or reset your password immediately.</p>
    </div>
    <div class="footer">
      <p>EchoThread &copy; 2026. All rights reserved.</p>
      <p>This is an automated operational email. Please do not reply directly.</p>
    </div>
  </div>
</body>
</html>
''';

    if (brevoApiKey == null || brevoApiKey.trim().isEmpty) {
      debugPrint('[NOTIFICATION_SERVICE] Brevo API Key missing. Simulating Email...');
      await _simulateNotification(
        email: email,
        name: name,
        type: 'email',
        title: 'Activity Notification - $activity',
        content: 'Activity: $activity, Time: $timestampStr, Receiver: $email',
      );
      return true;
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.brevo.com/v3/smtp/email'),
        headers: {
          'accept': 'application/json',
          'api-key': brevoApiKey,
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'sender': {'name': senderName, 'email': senderEmail},
          'to': [
            {'email': email, 'name': name}
          ],
          'subject': 'EchoThread Account Alert: $activity',
          'htmlContent': htmlContent,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('[NOTIFICATION_SERVICE] Real email notification sent successfully to $email.');
        return true;
      } else {
        debugPrint('[NOTIFICATION_SERVICE] Real email failed. Status Code: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[NOTIFICATION_SERVICE] Error sending email: $e');
      return false;
    }
  }

  /// Sends a real or simulated SMS notification.
  static Future<bool> sendSMS({
    required String phone,
    required String name,
    required String activity, // 'Registration' or 'Login'
    required DateTime dateTime,
  }) async {
    final config = await _getConfig();
    final brevoApiKey = config['brevo_api_key'] as String?;
    final twilioSid = config['twilio_account_sid'] as String?;
    final twilioToken = config['twilio_auth_token'] as String?;
    final twilioFrom = config['twilio_from'] as String?;
    final provider = config['sms_provider'] as String? ?? 'brevo';

    final timestampStr = dateTime.toLocal().toString().substring(0, 19);
    final smsBody = "EchoThread Confirm: Successful $activity for $name on $timestampStr. Thank you!";

    // If both Twilio and Brevo are missing or configured as simulated
    if (provider == 'simulated' ||
        (provider == 'twilio' && (twilioSid == null || twilioToken == null || twilioFrom == null)) ||
        (provider == 'brevo' && (brevoApiKey == null || brevoApiKey.trim().isEmpty))) {
      debugPrint('[NOTIFICATION_SERVICE] SMS config missing. Simulating SMS...');
      await _simulateNotification(
        email: phone,
        name: name,
        type: 'sms',
        title: 'SMS to $phone',
        content: smsBody,
      );
      return true;
    }

    if (provider == 'twilio') {
      try {
        final uri = Uri.parse('https://api.twilio.com/2010-04-01/Accounts/$twilioSid/Messages.json');
        final response = await http.post(
          uri,
          headers: {
            'Authorization': 'Basic ${base64Encode(utf8.encode('$twilioSid:$twilioToken'))}',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'From': twilioFrom,
            'To': phone,
            'Body': smsBody,
          },
        );

        if (response.statusCode == 201 || response.statusCode == 200) {
          debugPrint('[NOTIFICATION_SERVICE] Real Twilio SMS sent to $phone.');
          return true;
        } else {
          debugPrint('[NOTIFICATION_SERVICE] Twilio SMS failed: Status ${response.statusCode}, Body: ${response.body}');
          return false;
        }
      } catch (e) {
        debugPrint('[NOTIFICATION_SERVICE] Twilio SMS error: $e');
        return false;
      }
    } else {
      // Send using Brevo Transactional SMS API
      try {
        final response = await http.post(
          Uri.parse('https://api.brevo.com/v3/transactionalSMS/sms'),
          headers: {
            'accept': 'application/json',
            'api-key': brevoApiKey!,
            'content-type': 'application/json',
          },
          body: jsonEncode({
            'sender': config['sms_sender'] as String? ?? 'EchoThread',
            'recipient': phone,
            'content': smsBody,
            'type': 'transactional',
          }),
        );

        if (response.statusCode == 201 || response.statusCode == 200) {
          debugPrint('[NOTIFICATION_SERVICE] Real Brevo SMS sent to $phone.');
          return true;
        } else {
          debugPrint('[NOTIFICATION_SERVICE] Brevo SMS failed: Status ${response.statusCode}, Body: ${response.body}');
          return false;
        }
      } catch (e) {
        debugPrint('[NOTIFICATION_SERVICE] Brevo SMS error: $e');
        return false;
      }
    }
  }

  /// Writes a notification record to the `simulated_notifications` collection in Firestore.
  static Future<void> _simulateNotification({
    required String email,
    required String name,
    required String type,
    required String title,
    required String content,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('simulated_notifications').add({
        'recipient': email,
        'name': name,
        'type': type,
        'title': title,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('[NOTIFICATION_SERVICE] Logged simulated $type in Firestore.');
    } catch (e) {
      debugPrint('[NOTIFICATION_SERVICE] Error logging simulated notification: $e');
    }
  }
}
