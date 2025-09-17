#!/usr/bin/env node

const API_URL = 'https://brrow-backend-nodejs-production.up.railway.app';

async function testEndpoints() {
  console.log('🔄 Testing Railway Backend Status...\n');

  // 1. Test Health
  console.log('1️⃣ Testing Health Endpoint...');
  try {
    const healthRes = await fetch(`${API_URL}/health`);
    const health = await healthRes.json();
    console.log('✅ Health Check:', health);
    console.log('   Database:', health.database);
    console.log('   Environment:', health.environment);
  } catch (error) {
    console.log('❌ Health check failed:', error.message);
  }

  // 2. Test Login to get token
  console.log('\n2️⃣ Testing Login...');
  let token = null;
  try {
    const loginRes = await fetch(`${API_URL}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: 'shalin_sjsu',
        password: 'test123'
      })
    });

    if (!loginRes.ok) {
      // Try with email if username fails
      const emailLoginRes = await fetch(`${API_URL}/api/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: 'shalin.ratna@sjsu.edu',
          password: 'test123'
        })
      });

      if (emailLoginRes.ok) {
        const data = await emailLoginRes.json();
        token = data.token;
        console.log('✅ Login successful with email');
        console.log('   User:', data.user?.username || 'Unknown');
      } else {
        console.log('❌ Login failed with both username and email');
      }
    } else {
      const data = await loginRes.json();
      token = data.token;
      console.log('✅ Login successful');
      console.log('   User:', data.user?.username || 'Unknown');
    }
  } catch (error) {
    console.log('❌ Login error:', error.message);
  }

  if (!token) {
    console.log('\n⚠️ Cannot test authenticated endpoints without valid token');
    return;
  }

  // 3. Test GET /api/users/me
  console.log('\n3️⃣ Testing GET /api/users/me...');
  try {
    const meRes = await fetch(`${API_URL}/api/users/me`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });

    if (meRes.ok) {
      const data = await meRes.json();
      console.log('✅ User profile retrieved');
      console.log('   Username:', data.user?.username);
      console.log('   Email:', data.user?.email);
    } else {
      console.log('❌ Failed to get user profile:', meRes.status);
      const error = await meRes.text();
      console.log('   Error:', error.substring(0, 100));
    }
  } catch (error) {
    console.log('❌ Get user error:', error.message);
  }

  // 4. Test Username Change
  console.log('\n4️⃣ Testing Username Change...');
  const testUsername = `test_${Date.now().toString().slice(-6)}`;
  try {
    const changeRes = await fetch(`${API_URL}/api/users/change-username`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ newUsername: testUsername })
    });

    if (changeRes.ok) {
      const data = await changeRes.json();
      console.log('✅ Username change successful');
      console.log('   Old username:', data.oldUsername);
      console.log('   New username:', data.newUsername);
    } else {
      const error = await changeRes.json();
      console.log('❌ Username change failed:', changeRes.status);
      console.log('   Error:', error.error || error.message);
      if (error.daysRemaining) {
        console.log('   Days remaining:', error.daysRemaining);
      }
    }
  } catch (error) {
    console.log('❌ Username change error:', error.message);
  }

  // 5. Test Profile Picture Upload
  console.log('\n5️⃣ Testing Profile Picture Upload...');
  try {
    // Create a small test image (1x1 red pixel)
    const testImage = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==';

    const pictureRes = await fetch(`${API_URL}/api/users/me/profile-picture`, {
      method: 'PUT',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ image: testImage })
    });

    if (pictureRes.ok) {
      const data = await pictureRes.json();
      console.log('✅ Profile picture upload successful');
      console.log('   URL:', data.url);
    } else {
      console.log('❌ Profile picture upload failed:', pictureRes.status);
      const error = await pictureRes.text();
      console.log('   Error:', error.substring(0, 100));
    }
  } catch (error) {
    console.log('❌ Profile picture error:', error.message);
  }

  // 6. Test Listings
  console.log('\n6️⃣ Testing Listings Endpoint...');
  try {
    const listingsRes = await fetch(`${API_URL}/api/listings`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });

    if (listingsRes.ok) {
      const data = await listingsRes.json();
      console.log('✅ Listings retrieved');
      console.log('   Count:', data.listings?.length || 0);
    } else {
      console.log('❌ Listings failed:', listingsRes.status);
    }
  } catch (error) {
    console.log('❌ Listings error:', error.message);
  }
}

// Run tests
console.log('=================================');
console.log('  COMPREHENSIVE ENDPOINT TEST');
console.log('=================================\n');
testEndpoints().catch(console.error);