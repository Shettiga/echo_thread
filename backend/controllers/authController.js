const { auth, db, admin } = require('../config/firebase');
const { sendWelcomeEmail } = require('../services/emailService');
const { sendTwilioSMS } = require('../services/smsService');
const { verifyOTP } = require('../services/otpService');

/**
 * Register a new user in Firebase Auth, store their profile in Firestore,
 * and send welcome email & SMS.
 */
exports.register = async (req, res, next) => {
  try {
    // Failsafe parameter parsing (supports standard and Firebase callable payload wrapper)
    const body = req.body.data || req.body;
    const { email, password, name, phone, role } = body;

    if (!email || !password || !name || !role) {
      return res.status(400).json({ error: 'Email, password, name, and role are required fields.' });
    }

    // 1. Create User Account in Firebase Auth
    const userRecord = await auth.createUser({
      email,
      password,
      displayName: name
    });

    const uid = userRecord.uid;

    // 2. Store user profile details in Firestore
    await db.collection('users').doc(uid).set({
      name,
      email,
      phone: phone || '',
      role,
      profileImage: '',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // 3. Send notifications asynchronously (non-blocking)
    sendWelcomeEmail({ email, name, role }).catch(emailErr => {
      console.error('[Welcome Email Error]', emailErr);
    });

    if (phone) {
      const smsMsg = `Welcome ${name} to EchoThread! Your account has been successfully created. Thank you for joining!`;
      sendTwilioSMS(phone, smsMsg).catch(smsErr => {
        console.error('[Welcome SMS Error]', smsErr);
      });
    }

    res.status(200).json({
      success: true,
      uid,
      message: 'User registered successfully.'
    });
  } catch (err) {
    next(err);
  }
};

/**
 * Verifies OTP and resets the user's password in Firebase Authentication.
 */
exports.passwordReset = async (req, res, next) => {
  try {
    // Failsafe parsing
    const body = req.body.data || req.body;
    const { email, otp, newPassword } = body;

    if (!email || !otp || !newPassword) {
      return res.status(400).json({ error: 'Email, otp, and newPassword are required fields.' });
    }

    // Verify OTP from password_resets collection
    await verifyOTP('password_resets', email, otp);

    // Fetch user UID from email and update their password
    const userRecord = await auth.getUserByEmail(email);
    await auth.updateUser(userRecord.uid, {
      password: newPassword
    });

    console.log(`[AUTH] Successfully updated password for user: ${email} via OTP.`);

    // Return standard response structure and Failsafe Callable structure
    res.status(200).json({
      success: true,
      result: {
        success: true
      }
    });
  } catch (err) {
    console.error('[AUTH_ERROR] Error updating user password:', err);
    
    // Support Failsafe error rendering if called with Callable format
    if (req.body.data) {
      return res.status(200).json({
        result: {
          success: false,
          error: err.message || 'An error occurred while resetting password.'
        }
      });
    }
    next(err);
  }
};
