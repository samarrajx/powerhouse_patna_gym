const { sendGlobalPush } = require('./utils/fcm');

async function test() {
  console.log('🚀 Sending Test Push to Topic: all_users...');
  try {
    const response = await sendGlobalPush(
      'Test Notification 🔔', 
      'If you see this, notifications are working! Time: ' + new Date().toLocaleTimeString(),
      { test: "true", priority: "high" }
    );
    console.log('✅ Test Push Result:', response);
    process.exit(0);
  } catch (err) {
    console.error('❌ Test Push Failed:', err);
    process.exit(1);
  }
}

test();
