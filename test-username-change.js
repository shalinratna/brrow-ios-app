#!/usr/bin/env node

// Test username change functionality
const API_URL = 'https://brrow-backend-nodejs-production.up.railway.app';

// You need to get a valid token first - using a test token
const TEST_TOKEN = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJjbWZsYW5wcWEwMDA2bnowMXVhdWV6ZWZiIiwiZW1haWwiOiJzaGFsaW4ucmF0bmFAc2pzdS5lZHUiLCJpYXQiOjE3MjY0Mzc0NzcsImV4cCI6MTcyNzA0MjI3N30.cQZ-KvVCBrV1T8XXo7Y01k7Wduf21dCnD0ZT_EGIWXU';

async function testUsernameChange() {
  console.log('🔄 Testing username change endpoint...\n');

  // First, get current user profile
  console.log('1️⃣ Getting current user profile...');
  try {
    const profileResponse = await fetch(`${API_URL}/api/users/me`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${TEST_TOKEN}`,
        'Content-Type': 'application/json'
      }
    });

    if (profileResponse.status === 403 || profileResponse.status === 401) {
      console.log('❌ Token expired or invalid. You need to login first to get a fresh token.');
      console.log('\nTo get a fresh token:');
      console.log('1. Login via the app or API');
      console.log('2. Check the network logs for the token');
      console.log('3. Update TEST_TOKEN in this script');
      return;
    }

    const profileData = await profileResponse.json();
    console.log('Current username:', profileData.user?.username || 'Unknown');
    console.log('');

    // Test changing username
    const newUsername = `test_user_${Date.now()}`;
    console.log(`2️⃣ Attempting to change username to: ${newUsername}`);

    const changeResponse = await fetch(`${API_URL}/api/users/change-username`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${TEST_TOKEN}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ newUsername })
    });

    const changeData = await changeResponse.json();

    if (changeResponse.ok && changeData.success) {
      console.log('✅ Username changed successfully!');
      console.log('Response:', changeData);
    } else {
      console.log('❌ Failed to change username');
      console.log('Status:', changeResponse.status);
      console.log('Response:', changeData);

      if (changeData.daysRemaining) {
        console.log(`\n⏰ You can change username again in ${changeData.daysRemaining} days`);
      }
    }

    // Verify the change
    console.log('\n3️⃣ Verifying username change...');
    const verifyResponse = await fetch(`${API_URL}/api/users/me`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${TEST_TOKEN}`,
        'Content-Type': 'application/json'
      }
    });

    const verifyData = await verifyResponse.json();
    console.log('New username:', verifyData.user?.username || 'Unknown');

  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

// Run the test
console.log('=================================');
console.log('  USERNAME CHANGE TEST');
console.log('=================================\n');
testUsernameChange();