const { db, admin } = require('../config/firebase');

/**
 * Generates a secure 6-digit OTP code.
 */
function generateOTP() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

/**
 * Stores an OTP code in the specified Firestore collection.
 */
async function storeOTP(collectionName, docId, dataField, identifierValue, otp) {
  const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes expiry
  await db.collection(collectionName).doc(docId).set({
    [dataField]: identifierValue,
    otp: otp,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
  });
}

/**
 * Verifies an OTP code and deletes the document on success.
 */
async function verifyOTP(collectionName, docId, enteredOtp, deleteOnSuccess = true) {
  const docRef = db.collection(collectionName).doc(docId);
  const doc = await docRef.get();

  if (!doc.exists) {
    throw new Error('No active verification request found.');
  }

  const data = doc.data();
  const dbOtp = data.otp;
  const expiresAt = data.expiresAt.toDate();

  if (new Date() > expiresAt) {
    throw new Error('The verification code has expired. Please request a new one.');
  }

  if (enteredOtp !== dbOtp) {
    throw new Error('The verification code entered is incorrect.');
  }

  // OTP is correct and not expired. Delete the document if requested.
  if (deleteOnSuccess) {
    await docRef.delete();
  }
  return true;
}

module.exports = {
  generateOTP,
  storeOTP,
  verifyOTP
};
