#!/usr/bin/env node

const API_URL = 'https://brrow-backend-nodejs-production.up.railway.app';

async function testAuth() {
  console.log('Testing Railway Authentication...\n');

  // First try to register a test user
  console.log('1️⃣ Attempting to register test user...');
  try {
    const registerRes = await fetch(`${API_URL}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: 'shalin_test',
        email: 'shalin@test.com',
        password: 'test123',
        firstName: 'Shalin',
        lastName: 'Test'
      })
    });

    const registerText = await registerRes.text();
    console.log('Register response:', registerRes.status);
    if (registerText) {
      try {
        const registerData = JSON.parse(registerText);
        console.log('Register result:', registerData);
      } catch (e) {
        console.log('Register response (text):', registerText.substring(0, 200));
      }
    }
  } catch (error) {
    console.log('Register error:', error.message);
  }

  // Now try to login
  console.log('\n2️⃣ Attempting login...');
  try {
    const loginRes = await fetch(`${API_URL}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'shalin@test.com',
        password: 'test123'
      })
    });

    console.log('Login status:', loginRes.status);
    const loginText = await loginRes.text();
    if (loginText) {
      try {
        const loginData = JSON.parse(loginText);
        console.log('✅ Login successful!');
        console.log('Token:', loginData.token?.substring(0, 20) + '...');
        console.log('User:', loginData.user);
        return loginData.token;
      } catch (e) {
        console.log('Login response (text):', loginText.substring(0, 200));
      }
    }
  } catch (error) {
    console.log('Login error:', error.message);
  }

  return null;
}

async function testWithToken(token) {
  console.log('\n3️⃣ Testing authenticated endpoints with token...');
  
  // Test /api/users/me
  try {
    const meRes = await fetch(`${API_URL}/api/users/me`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    
    console.log('GET /api/users/me:', meRes.status);
    if (meRes.ok) {
      const data = await meRes.json();
      console.log('User data:', data.user);
    }
  } catch (error) {
    console.log('Error:', error.message);
  }

  // Test username change
  console.log('\n4️⃣ Testing username change...');
  const newUsername = `shalin_${Date.now().toString().slice(-6)}`;
  try {
    const changeRes = await fetch(`${API_URL}/api/users/change-username`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ newUsername })
    });
    
    console.log('Username change status:', changeRes.status);
    if (changeRes.ok) {
      const data = await changeRes.json();
      console.log('✅ Username changed from', data.oldUsername, 'to', data.newUsername);
    } else {
      const error = await changeRes.json();
      console.log('Username change error:', error);
    }
  } catch (error) {
    console.log('Error:', error.message);
  }

  // Test profile picture upload
  console.log('\n5️⃣ Testing profile picture upload...');
  try {
    // Small test image (1x1 red pixel)
    const testImage = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==';
    
    const picRes = await fetch(`${API_URL}/api/users/me/profile-picture`, {
      method: 'PUT',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ image: testImage })
    });
    
    console.log('Profile picture upload status:', picRes.status);
    if (picRes.ok) {
      const data = await picRes.json();
      console.log('✅ Profile picture uploaded:', data.url);
    } else {
      const error = await picRes.text();
      console.log('Upload error:', error.substring(0, 100));
    }
  } catch (error) {
    console.log('Error:', error.message);
  }
}

async function main() {
  console.log('=================================');
  console.log('   RAILWAY AUTH & PROFILE TEST');
  console.log('=================================\n');
  
  const token = await testAuth();
  if (token) {
    await testWithToken(token);
  } else {
    console.log('\n❌ Could not obtain auth token for testing');
  }
}

main().catch(console.error);