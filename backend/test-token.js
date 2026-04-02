const { sendToDevices } = require('./utils/fcm');

// PASTE YOUR TOKEN HERE from the Flutter logs
const YOUR_DEVICE_TOKEN = process.argv[2];

if (!YOUR_DEVICE_TOKEN) {
  console.error('❌ Please provide your FCM token as an argument: node test-token.js <YOUR_TOKEN>');
  process.exit(1);
}

async function test() {
  console.log('🚀 Sending Direct Test Push to Token:', YOUR_DEVICE_TOKEN);
  try {
    const response = await sendToDevices(
      [YOUR_DEVICE_TOKEN],
      'Direct FCM Test 🎯', 
      'This was sent directly to your token at: ' + new Date().toLocaleTimeString(),
      { direct: "true", priority: "high" }
    );
    console.log('✅ Direct Test Push Result:', response);
    process.exit(0);
  } catch (err) {
    console.error('❌ Direct Test Push Failed:', err);
    process.exit(1);
  }
}

test();
