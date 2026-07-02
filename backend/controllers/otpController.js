const { generateOTP, storeOTP, verifyOTP } = require('../services/otpService');
const { sendOtpEmail, sendPasswordResetEmail } = require('../services/emailService');
const { sendTwilioSMS } = require('../services/smsService');

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

    const userName = name || 'User';
    let collectionName = 'registration_otps';
    if (purpose === 'login') {
      collectionName = 'login_otps';
    } else if (purpose === 'forgotPassword') {
      collectionName = 'password_resets';
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
      message: 'Verification code sent to your email.'
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

    await verifyOTP(collectionName, email, otp);

    res.status(200).json({
      success: true,
      message: 'OTP verified successfully.'
    });
  } catch (err) {
    next(err);
  }
};

/**
 * Generates an OTP, stores it in Firestore, and sends it to the user's phone via Twilio.
 */
exports.sendSmsOtp = async (req, res, next) => {
  try {
    const body = req.body.data || req.body;
    const { phone } = body;

    if (!phone) {
      // Support Callable error format
      if (req.body.data) {
        return res.status(200).json({
          result: {
            success: false,
            error: 'The function must be called with a phone number.'
          }
        });
      }
      return res.status(400).json({ error: 'Phone number is required.' });
    }

    // 1. Generate 6-digit OTP
    const otp = generateOTP();

    // 2. Store OTP in Firestore
    await storeOTP('phone_otps', phone, 'phone', phone, otp);

    // 3. Send SMS (non-blocking)
    const message = `Your EchoThread OTP code is: ${otp}. It is valid for 5 minutes.`;
    sendTwilioSMS(phone, message).catch(smsErr => {
      console.error('[sendSMSOTP Error]', smsErr);
    });

    // Support both standard and Callable formats
    res.status(200).json({
      success: true,
      result: {
        success: true,
        message: 'OTP sent successfully.'
      }
    });
  } catch (err) {
    console.error('[sendSMSOTP Error]', err);
    if (req.body.data) {
      return res.status(200).json({
        result: {
          success: false,
          error: err.message || 'An error occurred while generating or sending OTP.'
        }
      });
    }
    next(err);
  }
};

/**
 * Verifies SMS OTP from Firestore.
 */
exports.verifySmsOtp = async (req, res, next) => {
  try {
    const body = req.body.data || req.body;
    const { phone, otp } = body;

    if (!phone || !otp) {
      if (req.body.data) {
        return res.status(200).json({
          result: {
            success: false,
            error: 'phone and otp code are required arguments.'
          }
        });
      }
      return res.status(400).json({ error: 'Phone and OTP are required fields.' });
    }

    await verifyOTP('phone_otps', phone, otp);

    // Support both standard and Callable formats
    res.status(200).json({
      success: true,
      result: {
        success: true
      }
    });
  } catch (err) {
    console.error('[verifySMSOTP Error]', err);
    if (req.body.data) {
      return res.status(200).json({
        result: {
          success: false,
          error: err.message || 'Verification failed.'
        }
      });
    }
    next(err);
  }
};
