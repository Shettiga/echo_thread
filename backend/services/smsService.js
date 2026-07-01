const twilio = require('twilio');
const { db, admin } = require('../config/firebase');

async function sendTwilioSMS(toPhone, message) {
  const accountSid = process.env.TWILIO_ACCOUNT_SID;
  const authToken = process.env.TWILIO_AUTH_TOKEN;
  const twilioNumber = process.env.TWILIO_NUMBER;

  if (!accountSid || !authToken || !twilioNumber) {
    console.log(`[SIMULATED SMS] To: ${toPhone}, Msg: ${message}`);
    await db.collection('simulated_notifications').add({
      recipient: toPhone,
      name: 'Twilio SMS',
      type: 'sms',
      title: 'SMS Alert (Simulated)',
      content: message,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
    return true;
  }

  try {
    const client = twilio(accountSid, authToken);
    const response = await client.messages.create({
      body: message,
      from: twilioNumber,
      to: toPhone,
    });
    console.log(`[TWILIO SMS SUCCESS] Msg SID: ${response.sid} to ${toPhone}`);
    return true;
  } catch (err) {
    console.error(`[TWILIO SMS ERROR] Failed to send SMS to ${toPhone}:`, err);
    // Write copy to simulated for review
    await db.collection('simulated_notifications').add({
      recipient: toPhone,
      name: 'Twilio SMS Error Log',
      type: 'sms',
      title: 'SMS delivery failure',
      content: `${message}\nError: ${err.message}`,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
    return false;
  }
}

module.exports = {
  sendTwilioSMS
};
