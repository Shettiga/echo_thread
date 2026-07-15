const express = require('express');
const router = express.Router();
const otpController = require('../controllers/otpController');

router.post('/send-email-otp', otpController.sendEmailOtp);
router.post('/verify-email-otp', otpController.verifyEmailOtp);

module.exports = router;
