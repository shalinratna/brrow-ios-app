#!/usr/bin/env node

const API_URL = 'https://brrow-backend-nodejs-production.up.railway.app';

async function createAndTestUser() {
  console.log('🚀 Creating and testing user on Railway backend...\n');

  // Step 1: Register a new user
  const testUser = {
    username: `test_${Date.now()}`,
    email: `test_${Date.now()}@test.com`,
    password: 'Test123!',
    firstName: 'Test',
    lastName: 'User'
  };

  console.log('1️⃣ Registering user:', testUser.username);
  
  try {
    const registerRes = await fetch(`${API_URL}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(testUser)
    });

    const registerData = await registerRes.json();
    console.log('Registration response:', registerRes.status);
    
    if (registerRes.ok) {
      console.log('✅ Registration successful!');
      console.log('Token:', registerData.token?.substring(0, 30) + '...');
    } else {
      console.log('❌ Registration failed:', registerData);
      return;
    }
  } catch (error) {
    console.log('❌ Registration error:', error.message);
    return;
  }

  // Step 2: Test login with the created user
  console.log('\n2️⃣ Testing login with new user...');
  
  try {
    const loginRes = await fetch(`${API_URL}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: testUser.username,
        password: testUser.password
      })
    });

    const loginData = await loginRes.json();
    console.log('Login response:', loginRes.status);
    
    if (loginRes.ok) {
      console.log('✅ Login successful!');
      console.log('Token:', loginData.accessToken?.substring(0, 30) + '...');
      console.log('User:', loginData.user);
      
      return loginData.accessToken;
    } else {
      console.log('❌ Login failed:', loginData);
    }
  } catch (error) {
    console.log('❌ Login error:', error.message);
  }

  return null;
}

async function testAuthenticatedEndpoints(token) {
  if (!token) {
    console.log('\n❌ No token available for testing authenticated endpoints');
    return;
  }

  console.log('\n3️⃣ Testing authenticated endpoints...\n');

  // Test GET /api/users/me
  try {
    const res = await fetch(`${API_URL}/api/users/me`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    
    console.log('GET /api/users/me:', res.status);
    if (res.ok) {
      const data = await res.json();
      console.log('User profile:', data.user);
    } else {
      const error = await res.text();
      console.log('Error:', error.substring(0, 100));
    }
  } catch (error) {
    console.log('Error:', error.message);
  }

  // Test username change
  console.log('\n4️⃣ Testing username change...');
  const newUsername = `changed_${Date.now().toString().slice(-6)}`;
  
  try {
    const res = await fetch(`${API_URL}/api/users/change-username`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ newUsername })
    });
    
    console.log('Username change status:', res.status);
    const data = await res.json();
    
    if (res.ok) {
      console.log('✅ Username changed successfully!');
      console.log('Old:', data.oldUsername, '-> New:', data.newUsername);
    } else {
      console.log('❌ Username change failed:', data);
    }
  } catch (error) {
    console.log('Error:', error.message);
  }

  // Test profile picture upload
  console.log('\n5️⃣ Testing profile picture upload...');
  
  try {
    // Small test image (1x1 pixel)
    const testImage = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==';
    
    const res = await fetch(`${API_URL}/api/users/me/profile-picture`, {
      method: 'PUT',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ image: testImage })
    });
    
    console.log('Profile picture upload status:', res.status);
    
    if (res.ok) {
      const data = await res.json();
      console.log('✅ Profile picture uploaded!');
      console.log('URL:', data.url || data.profilePictureUrl);
    } else {
      const error = await res.text();
      console.log('❌ Upload failed:', error.substring(0, 100));
    }
  } catch (error) {
    console.log('Error:', error.message);
  }

  // Test listings
  console.log('\n6️⃣ Testing listings endpoint...');
  
  try {
    const res = await fetch(`${API_URL}/api/listings`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    
    console.log('GET /api/listings:', res.status);
    if (res.ok) {
      const data = await res.json();
      console.log(`Found ${data.listings?.length || 0} listings`);
      if (data.listings?.length > 0) {
        console.log('First listing:', data.listings[0].title);
      }
    }
  } catch (error) {
    console.log('Error:', error.message);
  }
}

createAndTestUser().then(token => testAuthenticatedEndpoints(token));