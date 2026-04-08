require('dotenv').config();
const { sendToAll } = require('./utils/fcm');
const { isInitialized, getError } = require('./db/firebase');

async function test() {
  console.log('--- FCM Test Script ---');
  console.log('Initialization Status:', isInitialized());
  if (!isInitialized()) {
    console.error('Initialization Error:', getError());
    process.exit(1);
  }

  try {
    console.log('Attempting to send notification to all registered tokens...');
    const response = await sendToAll('TEST NOTIFICATION', 'This is a test notification from the backend debugging script.', {
      test: 'true',
      timestamp: new Date().toISOString()
    });
    console.log('Response from FCM:', JSON.stringify(response, null, 2));
    console.log('--- Test Complete ---');
  } catch (error) {
    console.error('--- Test Failed ---');
    console.error(error);
  }
}

test();
