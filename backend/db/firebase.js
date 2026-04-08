const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

let fcmInitialized = false;
let initError = null;

try {
  let serviceAccount;
  const serviceAccountPath = path.join(__dirname, '../config/firebase-service-account.json.json');

  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    try {
      console.log('⚡ Initializing Firebase from environment variable...');
      serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      // Fix for escaped newlines in private_key when coming from env vars
      if (serviceAccount.private_key) {
        serviceAccount.private_key = serviceAccount.private_key.replace(/\\n/g, '\n');
      }
    } catch (parseError) {
      console.error('❌ Failed to parse FIREBASE_SERVICE_ACCOUNT env var. Ensure it is valid JSON.', parseError.message);
      initError = `JSON Parse Error: ${parseError.message}`;
    }
  } else if (fs.existsSync(serviceAccountPath)) {
    try {
      console.log('📁 Initializing Firebase from local config file...');
      serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
    } catch (fileError) {
      console.error('❌ Failed to read local Firebase service account file:', fileError.message);
      initError = `File Read Error: ${fileError.message}`;
    }
  }

  if (serviceAccount && !initError) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    fcmInitialized = true;
    console.log(`✅ Firebase Admin initialized successfully (Project: ${serviceAccount.project_id})`);
  } else {
    if (!initError) {
      console.warn('⚠️ Firebase Admin NOT initialized: No credentials found in FIREBASE_SERVICE_ACCOUNT or config file.');
      initError = 'Credentials missing';
    }
  }
} catch (error) {
  initError = error.message;
  console.error('❌ Critical Error initializing Firebase Admin:', error);
}

module.exports = {
  admin,
  isInitialized: () => fcmInitialized,
  getError: () => initError
};
