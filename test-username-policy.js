#!/usr/bin/env node

const API_URL = 'https://brrow-backend-nodejs-production.up.railway.app';

async function testUsernamePolicy() {
  // Create and login
  const testUser = {
    username: `policy_test_${Date.now()}`,
    email: `policy_${Date.now()}@test.com`,
    password: 'Test123!',
    firstName: 'Policy',
    lastName: 'Test'
  };

  // Register
  await fetch(`${API_URL}/api/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(testUser)
  });

  // Login
  const loginRes = await fetch(`${API_URL}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      username: testUser.username,
      password: testUser.password
    })
  });

  const { accessToken } = await loginRes.json();
  console.log('✅ User created and logged in');

  // First username change - should succeed
  console.log('\n1️⃣ First username change attempt...');
  const change1 = await fetch(`${API_URL}/api/users/change-username`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ newUsername: `changed_${Date.now().toString().slice(-6)}` })
  });

  const result1 = await change1.json();
  console.log('Result:', change1.ok ? '✅ SUCCESS' : '❌ FAILED');
  console.log('Response:', result1);

  // Second username change - should be blocked by 90-day policy
  console.log('\n2️⃣ Second username change attempt (should be blocked)...');
  const change2 = await fetch(`${API_URL}/api/users/change-username`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ newUsername: `blocked_${Date.now().toString().slice(-6)}` })
  });

  const result2 = await change2.json();
  console.log('Result:', change2.status === 400 ? '✅ CORRECTLY BLOCKED' : '❌ POLICY NOT WORKING');
  console.log('Response:', result2);
}

testUsernamePolicy().catch(console.error);