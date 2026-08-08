const { initializeApp, cert } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore } = require("firebase-admin/firestore");
const { getStorage } = require("firebase-admin/storage");

function resolveCredential() {
  if (process.env.FIREBASE_SERVICE_ACCOUNT_PATH) {
    // Local development: point directly at the downloaded service account JSON file.
    // Avoids manually copy-pasting a multi-line private key into .env, which is
    // fragile on Windows (Notepad/clipboard tools can silently corrupt line breaks).
    return cert(require(process.env.FIREBASE_SERVICE_ACCOUNT_PATH));
  }
  // Production (Render/Railway/etc.): no filesystem to drop a JSON key into,
  // so individual env vars set directly in the hosting dashboard instead.
  return cert({
    projectId: process.env.FIREBASE_PROJECT_ID,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, "\n"),
  });
}

const app = initializeApp({
  credential: resolveCredential(),
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
});

module.exports = {
  auth: getAuth(app),
  db: getFirestore(app),
  storage: getStorage(app),
};