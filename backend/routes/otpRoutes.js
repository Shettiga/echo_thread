const express = require('express');
const router = express.Router();
const otpController = require('../controllers/otpController');

router.post('/send-email-otp', otpController.sendEmailOtp);
router.post('/verify-email-otp', otpController.verifyEmailOtp);
router.post('/send-sms-otp', otpController.sendSmsOtp);
router.post('/verify-sms-otp', otpController.verifySmsOtp);

module.exports = router;
