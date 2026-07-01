const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

router.post('/register', authController.register);
router.post('/password-reset', authController.passwordReset);

module.exports = router;
