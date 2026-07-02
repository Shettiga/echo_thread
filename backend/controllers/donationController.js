const { db, admin } = require('../config/firebase');
const {
  sendDonationCreatedEmail,
  sendDonationAcceptedEmail,
  sendDonationDeliveredEmail
} = require('../services/emailService');
const { sendTwilioSMS } = require('../services/smsService');

/**
 * Creates a new donation record in Firestore and sends notifications.
 */
exports.createDonation = async (req, res, next) => {
  try {
    const body = req.body.data || req.body;
    const {
      donorId,
      donorName,
      clothes,
      quantity,
      size,
      condition,
      location,
      imageUrl,
      pickupDate
    } = body;

    if (!donorId) {
      return res.status(400).json({ error: 'donorId is required to create a donation.' });
    }

    // 1. Create donation document in Firestore
    const donationData = {
      donorId,
      donorName: donorName || 'Donor',
      clothes: clothes || 'Clothes',
      quantity: quantity || '1',
      size: size || 'N/A',
      condition: condition || 'N/A',
      location: location || 'No pickup address specified',
      imageUrl: imageUrl || '',
      pickupDate: pickupDate || 'Soon',
      status: 'Pending',
      volunteerId: null,
      volunteerName: null,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    };

    const docRef = await db.collection('donations').add(donationData);

    // 2. Fetch donor details for notifications
    const donorSnap = await db.collection('users').doc(donorId).get();
    if (donorSnap.exists) {
      const donorData = donorSnap.data();
      const email = donorData.email;
      const name = donorData.name || 'Donor';
      const phone = donorData.phone;

      if (email) {
        sendDonationCreatedEmail({
          email,
          name,
          clothes: donationData.clothes,
          quantity: donationData.quantity,
          location: donationData.location,
          pickupDate: donationData.pickupDate
        }).catch(emailErr => {
          console.error('[Donation Created Email Error]', emailErr);
        });
      }

      if (phone) {
        const smsMsg = `Hi ${name}, your donation of ${donationData.clothes} (Qty: ${donationData.quantity}) has been created successfully. We'll update you when a volunteer accepts it.`;
        sendTwilioSMS(phone, smsMsg).catch(smsErr => {
          console.error('[Donation Created SMS Error]', smsErr);
        });
      }
    }

    res.status(200).json({
      success: true,
      donationId: docRef.id,
      message: 'Donation created successfully.'
    });
  } catch (err) {
    next(err);
  }
};

/**
 * Updates a donation record in Firestore. If the status changed, sends notifications.
 */
exports.updateDonation = async (req, res, next) => {
  try {
    const body = req.body.data || req.body;
    const { donationId, ...updateFields } = body;

    if (!donationId) {
      return res.status(400).json({ error: 'donationId is required to update a donation.' });
    }

    const donationRef = db.collection('donations').doc(donationId);
    const doc = await donationRef.get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Donation document not found.' });
    }

    const oldData = doc.data();
    const oldStatus = oldData.status;

    // Convert potential string date or timestamp helper to Firestore serverTimestamp
    const cleanedFields = { ...updateFields };
    if (cleanedFields.assignedAt === 'serverTimestamp') {
      cleanedFields.assignedAt = admin.firestore.FieldValue.serverTimestamp();
    }
    if (cleanedFields.deliveredAt === 'serverTimestamp') {
      cleanedFields.deliveredAt = admin.firestore.FieldValue.serverTimestamp();
    }

    // 1. Update document in Firestore
    await donationRef.update(cleanedFields);

    const newStatus = cleanedFields.status;

    // 2. If status has changed, perform trigger-like notifications
    if (newStatus && oldStatus !== newStatus) {
      const donorId = oldData.donorId;
      const volunteerId = cleanedFields.volunteerId || oldData.volunteerId;
      const clothes = cleanedFields.clothes || oldData.clothes || 'Clothes';
      const qty = cleanedFields.quantity || oldData.quantity || '1';
      const address = cleanedFields.location || oldData.location || 'N/A';

      // Get Donor Details
      const donorSnap = await db.collection('users').doc(donorId).get();
      if (donorSnap.exists) {
        const donorData = donorSnap.data();
        const donorEmail = donorData.email;
        const donorName = donorData.name || 'Donor';
        const donorPhone = donorData.phone;

        // A. Volunteer Accepted Donation
        if (newStatus === 'Accepted by Volunteer') {
          let volunteerName = cleanedFields.volunteerName || oldData.volunteerName || 'A Volunteer';
          let volunteerPhone = 'N/A';

          if (volunteerId) {
            const volSnap = await db.collection('users').doc(volunteerId).get();
            if (volSnap.exists) {
              volunteerName = volSnap.data().name || volunteerName;
              volunteerPhone = volSnap.data().phone || 'N/A';
            }
          }

          // Send email to donor
          if (donorEmail) {
            sendDonationAcceptedEmail({
              email: donorEmail,
              name: donorName,
              clothes,
              quantity: qty,
              location: address,
              volunteerName,
              volunteerPhone
            }).catch(emailErr => {
              console.error('[Donation Accepted Email Error]', emailErr);
            });
          }

          // Send SMS to donor
          if (donorPhone) {
            sendTwilioSMS(
              donorPhone,
              `Hi ${donorName}, volunteer ${volunteerName} has accepted your donation of ${clothes}. They will arrive shortly at: ${address}.`
            ).catch(smsErr => {
              console.error('[Donation Accepted Donor SMS Error]', smsErr);
            });
          }

          // Send SMS to volunteer
          if (volunteerId) {
            db.collection('users').doc(volunteerId).get().then(volSnap => {
              if (volSnap.exists && volSnap.data().phone) {
                sendTwilioSMS(
                  volSnap.data().phone,
                  `Hi ${volunteerName}, you have accepted the pickup for ${donorName}'s donation of ${clothes} at: ${address}.`
                ).catch(smsErr => {
                  console.error('[Donation Accepted Volunteer SMS Error]', smsErr);
                });
              }
            }).catch(err => console.error('[Fetch Volunteer Error]', err));
          }
        }

        // B. Donation Delivered / Completed
        if (newStatus === 'Delivered' || newStatus === 'Completed') {
          // Send email to donor
          if (donorEmail) {
            sendDonationDeliveredEmail({
              email: donorEmail,
              name: donorName,
              clothes,
              quantity: qty
            }).catch(emailErr => {
              console.error('[Donation Delivered Email Error]', emailErr);
            });
          }

          // Send SMS to donor
          if (donorPhone) {
            sendTwilioSMS(
              donorPhone,
              `Hi ${donorName}, thank you! Your donation of ${clothes} has been successfully completed and delivered.`
            ).catch(smsErr => {
              console.error('[Donation Delivered Donor SMS Error]', smsErr);
            });
          }
        }
      }
    }

    res.status(200).json({
      success: true,
      message: 'Donation updated successfully.'
    });
  } catch (err) {
    next(err);
  }
};
