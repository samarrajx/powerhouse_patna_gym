const { admin, isInitialized } = require('../db/firebase');

/**
 * Send push notification to all users (Global)
 */
async function sendGlobalPush(title, body, data = {}) {
  if (!isInitialized()) {
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
  if (!isInitialized() || !tokens.length) {
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
  if (!isInitialized()) {
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
    if (uniqueTokens.length === 0) return;
    return await sendToDevices(uniqueTokens, title, body, data);
  } catch (err) {
    console.error('❌ Failed to send to all devices:', err);
    throw err;
  }
}

/**
 * Send push notification to a specific user (all their devices)
 */
async function sendToUser(userId, title, body, data = {}) {
  if (!isInitialized()) {
    console.warn('⚠️ FCM not initialized, skipping user push.');
    return;
  }

  try {
    const supabase = require('../db/supabase');
    const { data: tokenRecords, error } = await supabase
      .from('device_tokens')
      .select('token')
      .eq('user_id', userId);
    
    if (error) throw error;
    if (!tokenRecords || tokenRecords.length === 0) {
      console.log(`ℹ️ No device tokens found for user: ${userId}`);
      return;
    }

    const tokens = tokenRecords.map(r => r.token);
    return await sendToDevices(tokens, title, body, data);
  } catch (err) {
    console.error(`❌ Failed to send to user ${userId}:`, err);
    throw err;
  }
}

module.exports = { sendGlobalPush, sendToDevices, sendToAll, sendToUser };
