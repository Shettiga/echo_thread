const { generateOTP, storeOTP, verifyOTP } = require('../services/otpService');
const { sendOtpEmail, sendPasswordResetEmail } = require('../services/emailService');
const { db } = require('../config/firebase');

/**
 * Generates an OTP, stores it in Firestore, and sends it to the user's email.
 */
exports.sendEmailOtp = async (req, res, next) => {
  try {
    const body = req.body.data || req.body;
    const { email, name, purpose } = body;

    if (!email || !purpose) {
      return res.status(400).json({ error: 'Email and purpose are required fields.' });
    }

    let userName = name || 'User';
    let collectionName = 'registration_otps';
    if (purpose === 'login') {
      collectionName = 'login_otps';
    } else if (purpose === 'forgotPassword') {
      collectionName = 'password_resets';
      
      // Check if user exists in Firestore
      const userQuery = await db.collection('users')
        .where('email', '==', email)
        .limit(1)
        .get();

      if (userQuery.empty) {
        return res.status(404).json({ error: 'Account not found. Please register first.' });
      }

      const userData = userQuery.docs[0].data();
      userName = userData.name || userName;
    }

    // 1. Generate 6-digit OTP
    const otp = generateOTP();

    // 2. Store OTP in Firestore
    await storeOTP(collectionName, email, 'email', email, otp);

    // 3. Send Email OTP (non-blocking)
    if (purpose === 'forgotPassword') {
      sendPasswordResetEmail({ email, name: userName, otp }).catch(err => {
        console.error('[sendEmailOtp Error - forgotPassword]', err);
      });
    } else {
      sendOtpEmail({ email, name: userName, otp, purpose }).catch(err => {
        console.error('[sendEmailOtp Error - OTP]', err);
      });
    }

    res.status(200).json({
      success: true,
      message: 'Verification code sent to your email.',
      name: userName
    });
  } catch (err) {
    next(err);
  }
};

/**
 * Verifies email OTP from Firestore.
 */
exports.verifyEmailOtp = async (req, res, next) => {
  try {
    const body = req.body.data || req.body;
    const { email, otp, purpose } = body;

    if (!email || !otp || !purpose) {
      return res.status(400).json({ error: 'Email, otp, and purpose are required fields.' });
    }

    let collectionName = 'registration_otps';
    if (purpose === 'login') {
      collectionName = 'login_otps';
    } else if (purpose === 'forgotPassword') {
      collectionName = 'password_resets';
    }

    const shouldDelete = purpose !== 'forgotPassword';
    await verifyOTP(collectionName, email, otp, shouldDelete);

    res.status(200).json({
      success: true,
      message: 'OTP verified successfully.'
    });
  } catch (err) {
    next(err);
  }
};

