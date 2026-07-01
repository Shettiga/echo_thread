const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");

let serviceAccount;

// Local development (uses the JSON file)
if (process.env.NODE_ENV !== "production") {
  serviceAccount = require("../firebase-admin-key.json");
}
// Render / Production (uses environment variable)
else {
  serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
}

initializeApp({
  credential: cert(serviceAccount),
});

const db = getFirestore();
const auth = getAuth();

const admin = {
  firestore: {
    FieldValue,
    Timestamp,
  },
};

module.exports = { admin, db, auth };