require('dotenv').config();
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');
const twilio = require('twilio');

admin.initializeApp();
const db = admin.firestore();

// Helper to send professional HTML emails
async function sendHTMLEmail({ toEmail, subject, title, userName, detailsHtml, contactInfo }) {
  const host = process.env.SMTP_HOST || 'smtp.gmail.com';
  const port = parseInt(process.env.SMTP_PORT || '587');
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;
  const from = process.env.SMTP_FROM || 'noreply@echothread.org';

  const hasConfig = user && user !== 'test@gmail.com' && pass && pass !== 'password';

  if (!hasConfig) {
    console.log(`[SIMULATED EMAIL] To: ${toEmail}, Subject: ${subject}`);
    await db.collection('simulated_notifications').add({
      recipient: toEmail,
      name: userName,
      type: 'email',
      title: subject,
      content: `Title: ${title}\nUser: ${userName}\nDetails: ${detailsHtml}\nContact: ${contactInfo}`,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
    return;
  }

  try {
    const transporter = nodemailer.createTransport({
      host: host,
      port: port,
      secure: port === 465,
      auth: { user, pass },
    });

    const htmlContent = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>${title}</title>
      <style>
        body { font-family: Arial, sans-serif; background-color: #f4f7f5; margin: 0; padding: 0; }
        .container { max-width: 600px; margin: 40px auto; background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 8px 24px rgba(0,0,0,0.06); border: 1px solid #e1e8e3; }
        .header { background: linear-gradient(135deg, #2e7d32, #43a047); padding: 30px 20px; text-align: center; color: #ffffff; }
        .header h1 { margin: 0; font-size: 26px; font-weight: bold; }
        .content { padding: 40px 30px; color: #333333; }
        .content h2 { font-size: 20px; color: #2e7d32; margin-top: 0; }
        .details-table { width: 100%; margin: 24px 0; border-collapse: collapse; }
        .details-table td { padding: 12px 8px; border-bottom: 1px solid #eff3f0; font-size: 14px; }
        .details-table td.label { font-weight: bold; color: #555555; width: 30%; }
        .details-table td.value { color: #222222; }
        .footer { background-color: #f8faf9; padding: 20px; text-align: center; font-size: 12px; color: #777777; border-top: 1px solid #eff3f0; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>EchoThread</h1>
          <p style="margin: 5px 0 0 0; opacity: 0.9;">Connecting Donors, NGOs & Volunteers</p>
        </div>
        <div class="content">
          <h2>${title}</h2>
          <p>Hello <strong>${userName}</strong>,</p>
          ${detailsHtml}
          <br/>
          <p><strong>Contact Information:</strong> ${contactInfo}</p>
        </div>
        <div class="footer">
          <p>EchoThread &copy; 2026. All rights reserved.</p>
        </div>
      </div>
    </body>
    </html>
    `;

    await transporter.sendMail({
      from: `"EchoThread Platform" <${from}>`,
      to: toEmail,
      subject: subject,
      html: htmlContent,
    });
    console.log(`[EMAIL SENT SUCCESS] To: ${toEmail}`);
  } catch (err) {
    console.error(`[EMAIL ERROR] Failed sending to ${toEmail}:`, err);
  }
}

// Helper to send SMS via Twilio
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

/**
 * Callable Cloud Function: sendSMSOTP
 * Generates 6-digit OTP code, stores it in Firestore, and sends it via Twilio.
 */
exports.sendSMSOTP = functions.https.onCall(async (data, context) => {
  const phone = data.phone;
  if (!phone) {
    throw new functions.https.HttpsError('invalid-argument', 'The function must be called with a phone number.');
  }

  // 1. Generate 6-digit OTP
  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes

  try {
    // 2. Save OTP to Firestore
    await db.collection('phone_otps').doc(phone).set({
      phone: phone,
      otp: otp,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
    });

    // 3. Send via Twilio
    const message = `Your EchoThread OTP code is: ${otp}. It is valid for 5 minutes.`;
    await sendTwilioSMS(phone, message);

    return { success: true, message: 'OTP sent successfully.' };
  } catch (err) {
    console.error('[sendSMSOTP Error]', err);
    throw new functions.https.HttpsError('internal', err.message || 'An error occurred while generating or sending OTP.');
  }
});

/**
 * Callable Cloud Function: verifySMSOTP
 * Matches entered OTP with Firestore records.
 */
exports.verifySMSOTP = functions.https.onCall(async (data, context) => {
  const phone = data.phone;
  const otp = data.otp;

  if (!phone || !otp) {
    throw new functions.https.HttpsError('invalid-argument', 'phone and otp code are required arguments.');
  }

  const otpDocRef = db.collection('phone_otps').doc(phone);
  const doc = await otpDocRef.get();

  if (!doc.exists) {
    throw new functions.https.HttpsError('not-found', 'No active OTP verification request found for this phone.');
  }

  const otpData = doc.data();
  const dbOtp = otpData.otp;
  const expiresAt = otpData.expiresAt.toDate();

  if (new Date() > expiresAt) {
    throw new functions.https.HttpsError('failed-precondition', 'The OTP code has expired. Please request a new one.');
  }

  if (otp !== dbOtp) {
    throw new functions.https.HttpsError('invalid-argument', 'The OTP code entered is incorrect.');
  }

  // Success: delete document to prevent replay
  await otpDocRef.delete();
  return { success: true };
});

/**
 * Callable Cloud Function: resetPasswordWithOTP
 * Validates OTP code from Firestore collection 'password_resets' and updates user password.
 */
exports.resetPasswordWithOTP = functions.https.onCall(async (data, context) => {
  const email = data.email;
  const otp = data.otp;
  const newPassword = data.newPassword;

  if (!email || !otp || !newPassword) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'The function must be called with three arguments: email, otp, and newPassword.'
    );
  }

  const resetDocRef = db.collection('password_resets').doc(email);
  const doc = await resetDocRef.get();

  if (!doc.exists) {
    throw new functions.https.HttpsError(
      'not-found',
      'No active password reset request found for this email address.'
    );
  }

  const resetData = doc.data();
  const dbOtp = resetData.otp;
  const expiresAt = resetData.expiresAt.toDate();

  if (new Date() > expiresAt) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'The OTP code has expired. Please request a new one.'
    );
  }

  if (otp !== dbOtp) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'The OTP code entered is incorrect.'
    );
  }

  try {
    const userRecord = await admin.auth().getUserByEmail(email);
    const uid = userRecord.uid;

    await admin.auth().updateUser(uid, {
      password: newPassword,
    });

    await resetDocRef.delete();
    console.log(`[AUTH] Successfully updated password for user: ${email} via OTP.`);
    return { success: true };
  } catch (error) {
    console.error('[AUTH_ERROR] Error updating user password:', error);
    throw new functions.https.HttpsError(
      'internal',
      error.message || 'An error occurred while attempting to update the user account.'
    );
  }
});

/**
 * Firestore Trigger: onUserCreated
 * Sends HTML Email and SMS notifications when a user registers.
 */
exports.onUserCreated = functions.firestore.document('users/{userId}').onCreate(async (snap, context) => {
  const userData = snap.data();
  const email = userData.email;
  const name = userData.name || 'User';
  const phone = userData.phone;
  const role = userData.role || 'Donor';

  if (!email) return;

  const detailsHtml = `
    <p>Thank you for registering on <strong>EchoThread</strong>. Your account has been setup successfully!</p>
    <table class="details-table">
      <tr><td class="label">Name</td><td class="value">${name}</td></tr>
      <tr><td class="label">Email</td><td class="value">${email}</td></tr>
      <tr><td class="label">Phone</td><td class="value">${phone || 'N/A'}</td></tr>
      <tr><td class="label">Role</td><td class="value">${role}</td></tr>
      <tr><td class="label">Date</td><td class="value">${new Date().toLocaleString()}</td></tr>
    </table>
    <p>We are excited to have you join our platform. Let's make a difference together!</p>
  `;

  // Send Email
  await sendHTMLEmail({
    toEmail: email,
    subject: 'Welcome to EchoThread! 🎉',
    title: 'Account Registration Confirmation',
    userName: name,
    detailsHtml: detailsHtml,
    contactInfo: 'Email: support@echothread.org | Web: www.echothread.org',
  });

  // Send SMS
  if (phone) {
    const smsMsg = `Welcome ${name} to EchoThread! Your account has been successfully created. Thank you for joining!`;
    await sendTwilioSMS(phone, smsMsg);
  }
});

/**
 * Firestore Trigger: onDonationCreated
 * Sends SMS and HTML Email notifications when a donation is created.
 */
exports.onDonationCreated = functions.firestore.document('donations/{donationId}').onCreate(async (snap, context) => {
  const donationData = snap.data();
  const donorId = donationData.donorId;
  const clothes = donationData.clothes || 'Clothes';
  const qty = donationData.quantity || '1';
  const address = donationData.location || 'No pickup address specified';
  const pickupDate = donationData.pickupDate || 'Soon';

  if (!donorId) return;

  // Retrieve donor details
  const donorSnap = await db.collection('users').doc(donorId).get();
  if (!donorSnap.exists) return;

  const donorData = donorSnap.data();
  const email = donorData.email;
  const name = donorData.name || 'Donor';
  const phone = donorData.phone;

  if (!email) return;

  const detailsHtml = `
    <p>Your garment donation request has been submitted successfully and is pending NGO assignment.</p>
    <table class="details-table">
      <tr><td class="label">Garments</td><td class="value">${clothes}</td></tr>
      <tr><td class="label">Quantity</td><td class="value">${qty}</td></tr>
      <tr><td class="label">Pickup Address</td><td class="value">${address}</td></tr>
      <tr><td class="label">Scheduled Date</td><td class="value">${pickupDate}</td></tr>
      <tr><td class="label">Time</td><td class="value">${new Date().toLocaleString()}</td></tr>
    </table>
  `;

  // Send Email
  await sendHTMLEmail({
    toEmail: email,
    subject: 'Donation Created Successfully 📦',
    title: 'New Donation Request',
    userName: name,
    detailsHtml: detailsHtml,
    contactInfo: `Phone: ${phone || 'N/A'} | Email: ${email}`,
  });

  // Send SMS
  if (phone) {
    const smsMsg = `Hi ${name}, your donation of ${clothes} (Qty: ${qty}) has been created successfully. We'll update you when a volunteer accepts it.`;
    await sendTwilioSMS(phone, smsMsg);
  }
});

/**
 * Firestore Trigger: onDonationUpdated
 * Sends SMS/Email on Status change (Volunteer Accepted / Donation Delivered).
 */
exports.onDonationUpdated = functions.firestore.document('donations/{donationId}').onUpdate(async (change, context) => {
  const oldData = change.before.data();
  const newData = change.after.data();

  const oldStatus = oldData.status;
  const newStatus = newData.status;

  if (oldStatus === newStatus) return;

  const donorId = newData.donorId;
  const volunteerId = newData.volunteerId;
  const clothes = newData.clothes || 'Clothes';
  const qty = newData.quantity || '1';
  const address = newData.location || 'N/A';

  // Get Donor Details
  const donorSnap = await db.collection('users').doc(donorId).get();
  if (!donorSnap.exists) return;
  const donorData = donorSnap.data();
  const donorEmail = donorData.email;
  const donorName = donorData.name || 'Donor';
  const donorPhone = donorData.phone;

  // 1. Volunteer Accepted Donation
  if (newStatus === 'Accepted by Volunteer') {
    let volunteerName = newData.volunteerName || 'A Volunteer';
    let volunteerPhone = 'N/A';

    if (volunteerId) {
      const volSnap = await db.collection('users').doc(volunteerId).get();
      if (volSnap.exists) {
        volunteerName = volSnap.data().name || volunteerName;
        volunteerPhone = volSnap.data().phone || 'N/A';
      }
    }

    // Email to Donor
    const detailsHtml = `
      <p>Good news! Your donation has been accepted by volunteer <strong>${volunteerName}</strong> and is currently being processed for pickup.</p>
      <table class="details-table">
        <tr><td class="label">Garments</td><td class="value">${clothes}</td></tr>
        <tr><td class="label">Quantity</td><td class="value">${qty}</td></tr>
        <tr><td class="label">Pickup Address</td><td class="value">${address}</td></tr>
        <tr><td class="label">Volunteer Name</td><td class="value">${volunteerName}</td></tr>
        <tr><td class="label">Volunteer Contact</td><td class="value">${volunteerPhone}</td></tr>
      </table>
    `;

    await sendHTMLEmail({
      toEmail: donorEmail,
      subject: 'Volunteer Assigned to Your Donation 🚗',
      title: 'Donation Pickup in Progress',
      userName: donorName,
      detailsHtml: detailsHtml,
      contactInfo: `Volunteer: ${volunteerName} (${volunteerPhone}) | Donor: ${donorName} (${donorPhone || 'N/A'})`,
    });

    // SMS to Donor
    if (donorPhone) {
      await sendTwilioSMS(donorPhone, `Hi ${donorName}, volunteer ${volunteerName} has accepted your donation of ${clothes}. They will arrive shortly at: ${address}.`);
    }

    // SMS to Volunteer (if phone exists)
    if (volunteerId) {
      const volSnap = await db.collection('users').doc(volunteerId).get();
      if (volSnap.exists && volSnap.data().phone) {
        await sendTwilioSMS(volSnap.data().phone, `Hi ${volunteerName}, you have accepted the pickup for ${donorName}'s donation of ${clothes} at: ${address}.`);
      }
    }
  }

  // 2. Donation Delivered / Completed
  if (newStatus === 'Delivered' || newStatus === 'Completed') {
    // Email to Donor
    const detailsHtml = `
      <p>Thank you! Your donation has been successfully delivered and completed by our volunteer network.</p>
      <table class="details-table">
        <tr><td class="label">Garments</td><td class="value">${clothes}</td></tr>
        <tr><td class="label">Quantity</td><td class="value">${qty}</td></tr>
        <tr><td class="label">Status</td><td class="value" style="color: green; font-weight: bold;">DELIVERED / COMPLETED</td></tr>
        <tr><td class="label">Date & Time</td><td class="value">${new Date().toLocaleString()}</td></tr>
      </table>
      <p>Your contribution helps make the world a warmer and more sustainable place.</p>
    `;

    await sendHTMLEmail({
      toEmail: donorEmail,
      subject: 'Donation Successfully Completed! 🎉',
      title: 'Donation Completed',
      userName: donorName,
      detailsHtml: detailsHtml,
      contactInfo: `Donor: ${donorName} (${donorPhone || 'N/A'})`,
    });

    // SMS to Donor
    if (donorPhone) {
      await sendTwilioSMS(donorPhone, `Hi ${donorName}, thank you! Your donation of ${clothes} has been successfully completed and delivered.`);
    }
  }
});

/**
 * Firestore Trigger: onPasswordResetCreated
 * Sends HTML email with OTP code when password reset is requested.
 */
exports.onPasswordResetCreated = functions.firestore.document('password_resets/{email}').onCreate(async (snap, context) => {
  const email = context.params.email;
  const resetData = snap.data();
  const otp = resetData.otp;

  if (!email || !otp) return;

  // Try to find userName
  const userQuery = await db.collection('users').where('email', '==', email).limit(1).get();
  const userName = userQuery.docs.length > 0 ? (userQuery.docs[0].data().name || 'User') : 'User';

  const detailsHtml = `
    <p>A request was made to reset your account password. Please enter the following 6-digit OTP code inside the EchoThread application to reset your password:</p>
    <div style="font-size: 24px; font-weight: bold; background-color: #f1f8f3; color: #2e7d32; padding: 12px; border-radius: 8px; text-align: center; letter-spacing: 4px; margin: 20px 0;">
      ${otp}
    </div>
    <p>This code will expire in <strong>5 minutes</strong>. If you did not make this request, you can safely ignore this email.</p>
  `;

  await sendHTMLEmail({
    toEmail: email,
    subject: 'Password Reset OTP Verification Code 🔑',
    title: 'Password Reset Request',
    userName: userName,
    detailsHtml: detailsHtml,
    contactInfo: 'Email: support@echothread.org',
  });
});
