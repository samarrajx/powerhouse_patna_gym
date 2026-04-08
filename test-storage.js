const jwt = require('jsonwebtoken');
const axios = require('axios');
require('dotenv').config({ path: './backend/.env' });

const secret = process.env.JWT_SECRET;
const token = jwt.sign({ userId: 'test-admin-id', role: 'admin' }, secret, { expiresIn: '1h' });

async function test() {
  try {
    console.log('Testing /admin/storage/overview...');
    const overview = await axios.get('http://localhost:3000/api/admin/storage/overview', {
      headers: { Authorization: `Bearer ${token}` }
    });
    console.log('Overview:', JSON.stringify(overview.data, null, 2));

    console.log('\nTesting /admin/storage/tables...');
    const tables = await axios.get('http://localhost:3000/api/admin/storage/tables', {
      headers: { Authorization: `Bearer ${token}` }
    });
    console.log('Tables Count:', tables.data.length);
    console.log('First 3 tables:', JSON.stringify(tables.data.slice(0, 3), null, 2));

  } catch (error) {
    console.error('Error:', error.response?.status, error.response?.data || error.message);
  }
}

test();
