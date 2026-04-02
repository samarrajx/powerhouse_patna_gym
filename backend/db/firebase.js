const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

try {
  let serviceAccount;
  const serviceAccountPath = path.join(__dirname, '../config/firebase-service-account.json.json');

  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    // Priority 1: Environment variable (useful for Vercel/Render)
    console.log('⚡ Initializing Firebase from environment variable...');
    serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  } else if (fs.existsSync(serviceAccountPath)) {
    // Priority 2: Local file
    console.log('📁 Initializing Firebase from local config file...');
    serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
  }

  if (serviceAccount) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    console.log('✅ Firebase Admin initialized successfully');
  } else {
    console.warn('⚠️ Firebase Admin NOT initialized: No credentials found in ENV or FILE.');
  }
} catch (error) {
  console.error('❌ Error initializing Firebase Admin:', error);
}

module.exports = admin;
