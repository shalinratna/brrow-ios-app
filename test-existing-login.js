#!/usr/bin/env node

const API_URL = 'https://brrow-backend-nodejs-production.up.railway.app';

async function testLogin() {
  console.log('Testing login with existing user...\n');

  // Try various login combinations
  const attempts = [
    { email: 'shalin@test.com', password: 'test123' },
    { email: 'shalin.ratna@sjsu.edu', password: 'test123' },
    { username: 'shalin_sjsu', password: 'test123' },
    { email: 'test@test.com', password: 'test123' },
    { username: 'testuser', password: 'test123' }
  ];

  for (const creds of attempts) {
    console.log(`Trying: ${creds.email || creds.username}...`);
    try {
      const res = await fetch(`${API_URL}/api/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(creds)
      });

      const text = await res.text();
      if (res.ok) {
        const data = JSON.parse(text);
        console.log(`✅ SUCCESS with ${creds.email || creds.username}!`);
        console.log('Token:', data.token?.substring(0, 30) + '...');
        console.log('User:', JSON.stringify(data.user, null, 2));
        return data.token;
      } else {
        console.log(`❌ Failed (${res.status}):`, text.substring(0, 100));
      }
    } catch (error) {
      console.log(`❌ Error:`, error.message);
    }
    console.log();
  }

  return null;
}

async function testAuthEndpoints(token) {
  if (!token) {
    console.log('\n👉 No valid token - cannot test authenticated endpoints');
    return;
  }

  console.log('\n🔄 Testing authenticated endpoints...\n');

  // Test /api/users/me
  try {
    const res = await fetch(`${API_URL}/api/users/me`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    console.log(`GET /api/users/me: ${res.status}`);
    if (res.ok) {
      const data = await res.json();
      console.log('User profile:', JSON.stringify(data.user, null, 2));
    }
  } catch (error) {
    console.log('Error:', error.message);
  }

  // Test listings
  try {
    const res = await fetch(`${API_URL}/api/listings`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    console.log(`\nGET /api/listings: ${res.status}`);
    if (res.ok) {
      const data = await res.json();
      console.log(`Listings count: ${data.listings?.length || 0}`);
    }
  } catch (error) {
    console.log('Error:', error.message);
  }
}

testLogin().then(token => testAuthEndpoints(token));