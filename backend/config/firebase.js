const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
const path = require('path');

// Resolve path to the Service Account Key file
const serviceAccountPath = path.resolve(__dirname, '../firebase-admin-key.json');
const serviceAccount = require(serviceAccountPath);

const app = initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();
const auth = getAuth();

// Expose admin helper namespace to avoid changing any of the business logic in services/controllers
const admin = {
  firestore: {
    FieldValue,
    Timestamp
  }
};

module.exports = { admin, db, auth };
