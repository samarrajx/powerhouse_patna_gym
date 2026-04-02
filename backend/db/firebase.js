const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

let fcmInitialized = false;
let initError = null;

try {
  let serviceAccount;
  const serviceAccountPath = path.join(__dirname, '../config/firebase-service-account.json.json');

  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    console.log('⚡ Initializing Firebase from environment variable...');
    serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    // Fix for escaped newlines in private_key when coming from env vars
    if (serviceAccount.private_key) {
      serviceAccount.private_key = serviceAccount.private_key.replace(/\\n/g, '\n');
    }
  } else if (fs.existsSync(serviceAccountPath)) {
    console.log('📁 Initializing Firebase from local config file...');
    serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
  }

  if (serviceAccount) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    fcmInitialized = true;
    console.log('✅ Firebase Admin initialized successfully');
  } else {
    console.warn('⚠️ Firebase Admin NOT initialized: No credentials found.');
    initError = 'No credentials found in ENV or FILE';
  }
} catch (error) {
  initError = error.message;
  console.error('❌ Error initializing Firebase Admin:', error);
}

module.exports = {
  admin,
  isInitialized: () => fcmInitialized,
  getError: () => initError
};
