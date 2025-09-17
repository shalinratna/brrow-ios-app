#!/usr/bin/env node

const API_URL = 'https://brrow-backend-nodejs-production.up.railway.app';

async function testUsernameChange() {
  // First create and login a test user
  const testUser = {
    username: `test_${Date.now()}`,
    email: `test_${Date.now()}@test.com`,
    password: 'Test123!',
    firstName: 'Test',
    lastName: 'User'
  };

  console.log('Creating test user:', testUser.username);

  // Register
  const registerRes = await fetch(`${API_URL}/api/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(testUser)
  });

  if (!registerRes.ok) {
    console.log('Registration failed:', await registerRes.text());
    return;
  }

  // Login
  const loginRes = await fetch(`${API_URL}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      username: testUser.username,
      password: testUser.password
    })
  });

  const loginData = await loginRes.json();
  const token = loginData.accessToken;

  console.log('\nLogged in successfully');
  console.log('Token:', token?.substring(0, 30) + '...');

  // Test username change
  const newUsername = `changed_${Date.now().toString().slice(-6)}`;
  console.log('\nChanging username to:', newUsername);

  const changeRes = await fetch(`${API_URL}/api/users/change-username`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ newUsername })
  });

  console.log('Response status:', changeRes.status);
  const changeData = await changeRes.json();

  if (changeRes.ok) {
    console.log('✅ Username changed successfully!');
    console.log('Result:', changeData);
  } else {
    console.log('❌ Username change failed!');
    console.log('Error response:', JSON.stringify(changeData, null, 2));
  }
}

testUsernameChange().catch(console.error);