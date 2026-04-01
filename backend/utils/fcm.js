const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

let fcmInitialized = false;

try {
  const serviceAccountPath = path.join(__dirname, '../config/firebase-service-account.json');
  if (fs.existsSync(serviceAccountPath)) {
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    fcmInitialized = true;
    console.log('✅ FCM Initialized');
  } else {
    console.warn('⚠️ FCM Service Account missing at:', serviceAccountPath);
  }
} catch (error) {
  console.error('❌ FCM Initialization Error:', error);
}

/**
 * Send push notification to all users (Global)
 */
async function sendGlobalPush(title, body, data = {}) {
  if (!fcmInitialized) return;

  const message = {
    notification: { title, body },
    topic: 'all_users', // Frontend should subscribe to 'all_users'
    data: { ...data, click_action: 'FLUTTER_NOTIFICATION_CLICK' }
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('Successfully sent global message:', response);
  } catch (error) {
    console.error('Error sending global message:', error);
  }
}

/**
 * Send push notification to specific device tokens
 */
async function sendToDevices(tokens, title, body, data = {}) {
  if (!fcmInitialized || !tokens.length) return;

  const message = {
    notification: { title, body },
    tokens: tokens,
    data: { ...data, click_action: 'FLUTTER_NOTIFICATION_CLICK' }
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(`${response.successCount} messages were sent successfully`);
  } catch (error) {
    console.error('Error sending multicast message:', error);
  }
}

module.exports = { sendGlobalPush, sendToDevices };
