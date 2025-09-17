#!/usr/bin/env node

// Test backend status and username change
const API_URL = 'https://brrow-backend-nodejs-production.up.railway.app';

async function testBackend() {
  console.log('🔄 Testing backend status...\n');

  // Test health endpoint
  try {
    const healthResponse = await fetch(`${API_URL}/health`);
    const healthData = await healthResponse.json();
    console.log('✅ Health check:', healthData);
  } catch (error) {
    console.log('❌ Health check failed:', error.message);
  }

  // Test auth endpoint
  console.log('\n🔐 Testing login...');
  try {
    const loginResponse = await fetch(`${API_URL}/api/auth/login`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        username: 'shalin_sjsu',
        password: 'test123'
      })
    });

    const loginData = await loginResponse.json();

    if (loginResponse.ok && loginData.token) {
      console.log('✅ Login successful!');
      console.log('Token:', loginData.token.substring(0, 50) + '...');
      console.log('User:', loginData.user?.username || 'Unknown');

      // Test username change with the token
      console.log('\n📝 Testing username change...');
      const newUsername = `shalin_${Date.now()}`;

      const changeResponse = await fetch(`${API_URL}/api/users/change-username`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${loginData.token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ newUsername })
      });

      const changeData = await changeResponse.json();
      console.log('Username change response:', changeResponse.status);
      console.log('Response data:', changeData);

      if (changeResponse.ok) {
        console.log('✅ Username changed successfully!');
      } else {
        console.log('❌ Username change failed');
      }

    } else {
      console.log('❌ Login failed:', loginData);
    }
  } catch (error) {
    console.log('❌ Auth test failed:', error.message);
  }
}

// Run the test
console.log('=================================');
console.log('  BACKEND STATUS TEST');
console.log('=================================\n');
testBackend();