const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

const serviceAccountPath = path.join(__dirname, '../config/firebase-service-account.json.json');

try {
  if (fs.existsSync(serviceAccountPath)) {
    const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    console.log('✅ Firebase Admin initialized successfully');
  } else {
    console.error('❌ Firebase Service Account not found at:', serviceAccountPath);
  }
} catch (error) {
  console.error('❌ Error initializing Firebase Admin:', error);
}

module.exports = admin;
