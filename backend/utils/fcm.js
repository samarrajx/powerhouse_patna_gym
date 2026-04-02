const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

let fcmInitialized = false;

try {
  const serviceAccountPath = path.join(__dirname, '../config/firebase-service-account.json.json');
  if (fs.existsSync(serviceAccountPath)) {
    const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
      });
    }
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
  if (!fcmInitialized) {
    console.warn('⚠️ FCM not initialized, skipping global push.');
    return;
  }

  const message = {
    notification: { title, body },
    topic: 'all_users',
    data: { 
      ...data, 
      click_action: 'FLUTTER_NOTIFICATION_CLICK' 
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'high_importance_channel',
        priority: 'high',
        defaultSound: true,
        defaultVibrateTimings: true,
      }
    },
    apns: {
      payload: {
        aps: {
          contentAvailable: true,
          sound: 'default',
          badge: 1,
        }
      }
    }
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('Successfully sent global message:', response);
    return response;
  } catch (error) {
    console.error('Error sending global message:', error);
    throw error;
  }
}

/**
 * Send push notification to specific device tokens
 */
async function sendToDevices(tokens, title, body, data = {}) {
  if (!fcmInitialized || !tokens.length) {
    console.warn('⚠️ FCM not initialized or no tokens, skipping device push.');
    return;
  }

  const message = {
    notification: { title, body },
    tokens: tokens,
    data: { 
      ...data, 
      click_action: 'FLUTTER_NOTIFICATION_CLICK' 
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'high_importance_channel',
        priority: 'high',
        defaultSound: true,
        defaultVibrateTimings: true,
      }
    },
    apns: {
      payload: {
        aps: {
          contentAvailable: true,
          sound: 'default',
          badge: 1,
        }
      }
    }
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(`${response.successCount} messages were sent successfully`);
    return response;
  } catch (error) {
    console.error('Error sending multicast message:', error);
    throw error;
  }
}

/**
 * Send push notification to ALL registered device tokens in the database
 */
async function sendToAll(title, body, data = {}) {
  if (!fcmInitialized) {
    console.warn('⚠️ FCM not initialized, skipping global push.');
    return;
  }

  try {
    const supabase = require('../db/supabase');
    // Fetch all unique tokens
    const { data: tokenRecords, error } = await supabase
      .from('device_tokens')
      .select('token');
    
    if (error) throw error;
    
    const uniqueTokens = [...new Set(tokenRecords.map(r => r.token))];
    console.log(`🔍 fcm.js: Found ${uniqueTokens.length} unique tokens in DB.`);
    
    if (uniqueTokens.length === 0) {
      console.log('ℹ️ No device tokens found in database.');
      return;
    }

    console.log(`🚀 fcm.js: Dispatching to tokens:`, uniqueTokens);
    return await sendToDevices(uniqueTokens, title, body, data);
  } catch (err) {
    console.error('❌ Failed to send to all devices:', err);
    throw err;
  }
}

module.exports = { sendGlobalPush, sendToDevices, sendToAll };
