const express = require('express');
const router = express.Router();
const donationController = require('../controllers/donationController');

router.post('/create-donation', donationController.createDonation);
router.post('/update-donation', donationController.updateDonation);

module.exports = router;
