#!/usr/bin/env node

const API_URL = 'https://brrow-backend-nodejs-production.up.railway.app';

async function testListingCreate() {
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

  console.log('Logged in successfully');

  // Try to create a listing
  const listing = {
    title: 'Test Camera',
    description: 'A camera for testing',
    categoryId: 'electronics',
    dailyRate: 50
  };

  console.log('\nCreating listing:', listing);

  const createRes = await fetch(`${API_URL}/api/listings`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(listing)
  });

  console.log('Response status:', createRes.status);
  const result = await createRes.json();

  if (createRes.ok) {
    console.log('✅ Listing created successfully!');
    console.log('Result:', JSON.stringify(result, null, 2));
  } else {
    console.log('❌ Listing creation failed!');
    console.log('Error:', JSON.stringify(result, null, 2));
  }
}

testListingCreate().catch(console.error);