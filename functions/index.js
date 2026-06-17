const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

/**
 * Callable Cloud Function: resetPasswordWithOTP
 * Validates OTP code from Firestore collection 'password_resets'
 * and updates user password in Firebase Auth Admin SDK.
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

  const db = admin.firestore();

  // 1. Verify OTP document in Firestore
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

  // 2. Check Expiration
  if (new Date() > expiresAt) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'The OTP code has expired. Please request a new one.'
    );
  }

  // 3. Match code
  if (otp !== dbOtp) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'The OTP code entered is incorrect.'
    );
  }

  try {
    // 4. Fetch the user's UID in Firebase Authentication
    const userRecord = await admin.auth().getUserByEmail(email);
    const uid = userRecord.uid;

    // 5. Update user credentials
    await admin.auth().updateUser(uid, {
      password: newPassword,
    });

    // 6. Delete OTP document to prevent replay attacks
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
