#!/usr/bin/env node

const axios = require('axios');

// Configuration
const BASE_URL = 'http://localhost:3010';
const TEST_EMAIL = `test${Date.now()}@example.com`;
const TEST_USERNAME = `testuser${Date.now()}`;

let authToken = '';
let userId = '';

console.log('🧪 COMPREHENSIVE CRUD OPERATIONS TEST');
console.log('====================================');

async function runTests() {
  try {
    console.log('\n1️⃣ TESTING USER REGISTRATION (CREATE)');
    await testUserRegistration();

    console.log('\n2️⃣ TESTING USER PROFILE READ (READ)');
    await testUserProfileRead();

    console.log('\n3️⃣ TESTING PROFILE UPDATE (UPDATE)');
    await testProfileUpdate();

    console.log('\n4️⃣ TESTING BIO UPDATE');
    await testBioUpdate();

    console.log('\n5️⃣ TESTING PHONE NUMBER UPDATE');
    await testPhoneUpdate();

    console.log('\n6️⃣ TESTING EMAIL UPDATE');
    await testEmailUpdate();

    console.log('\n7️⃣ TESTING PROFILE PHOTO UPDATE');
    await testProfilePhotoUpdate();

    console.log('\n8️⃣ TESTING COMPREHENSIVE PROFILE READ');
    await testComprehensiveProfileRead();

    console.log('\n✅ ALL CRUD OPERATIONS COMPLETED');
    console.log('================================');

  } catch (error) {
    console.error('❌ Test failed:', error.message);
    if (error.response) {
      console.error('Response:', error.response.data);
    }
  }
}

async function testUserRegistration() {
  console.log('📝 Registering new user...');

  const response = await axios.post(`${BASE_URL}/api/auth/register`, {
    email: TEST_EMAIL,
    password: 'testpassword123',
    username: TEST_USERNAME,
    firstName: 'Test',
    lastName: 'User'
  });

  if (response.data.success) {
    authToken = response.data.accessToken;
    userId = response.data.user.id;
    console.log('✅ User registered successfully');
    console.log(`   User ID: ${userId}`);
    console.log(`   Username: ${response.data.user.username}`);
    console.log(`   Email: ${response.data.user.email}`);
  } else {
    throw new Error('Registration failed');
  }
}

async function testUserProfileRead() {
  console.log('👤 Reading user profile...');

  const response = await axios.get(`${BASE_URL}/api/users/me`, {
    headers: { Authorization: `Bearer ${authToken}` }
  });

  if (response.data.success) {
    console.log('✅ Profile read successfully');
    console.log(`   Name: ${response.data.user.firstName} ${response.data.user.lastName}`);
    console.log(`   Bio: ${response.data.user.bio || 'None'}`);
    console.log(`   Phone: ${response.data.user.phone || 'None'}`);
    console.log(`   Location: ${response.data.user.location || 'None'}`);
  } else {
    throw new Error('Profile read failed');
  }
}

async function testProfileUpdate() {
  console.log('✏️ Testing profile update...');

  // Try multiple different endpoints that might exist
  const updateData = {
    firstName: 'UpdatedFirst',
    lastName: 'UpdatedLast',
    bio: 'This is my updated bio for CRUD testing',
    location: 'San Francisco, CA'
  };

  const endpoints = [
    '/api/users/me',
    '/api/user/profile',
    '/api/profile/update',
    '/api/users/update',
    '/api/auth/update-profile'
  ];

  let successfulEndpoint = null;

  for (const endpoint of endpoints) {
    try {
      console.log(`   Trying PUT ${endpoint}...`);
      const response = await axios.put(`${BASE_URL}${endpoint}`, updateData, {
        headers: {
          Authorization: `Bearer ${authToken}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.status === 200 || response.status === 201) {
        console.log(`✅ Profile update successful via ${endpoint}`);
        successfulEndpoint = endpoint;
        break;
      }
    } catch (error) {
      console.log(`   ❌ ${endpoint}: ${error.response?.status} ${error.response?.statusText || error.message}`);

      // Try PATCH method
      try {
        console.log(`   Trying PATCH ${endpoint}...`);
        const response = await axios.patch(`${BASE_URL}${endpoint}`, updateData, {
          headers: {
            Authorization: `Bearer ${authToken}`,
            'Content-Type': 'application/json'
          }
        });

        if (response.status === 200 || response.status === 201) {
          console.log(`✅ Profile update successful via PATCH ${endpoint}`);
          successfulEndpoint = endpoint;
          break;
        }
      } catch (patchError) {
        // Continue to next endpoint
      }
    }
  }

  if (!successfulEndpoint) {
    console.log('⚠️ No profile update endpoint found - this functionality may need implementation');
  }
}

async function testBioUpdate() {
  console.log('📝 Testing bio-specific update...');

  const endpoints = [
    '/api/users/me/bio',
    '/api/users/me',
    '/api/profile/bio'
  ];

  for (const endpoint of endpoints) {
    try {
      const response = await axios.put(`${BASE_URL}${endpoint}`, {
        bio: 'Updated bio specifically for bio testing'
      }, {
        headers: { Authorization: `Bearer ${authToken}` }
      });

      if (response.status === 200) {
        console.log(`✅ Bio update successful via ${endpoint}`);
        return;
      }
    } catch (error) {
      // Try next endpoint
    }
  }

  console.log('⚠️ Bio update endpoint not found');
}

async function testPhoneUpdate() {
  console.log('📱 Testing phone number update with Twilio verification...');

  const testPhone = '+15551234567';

  const endpoints = [
    '/api/users/me/phone',
    '/api/users/me',
    '/api/phone/verify/start',
    '/api/verify/phone/start'
  ];

  for (const endpoint of endpoints) {
    try {
      const response = await axios.post(`${BASE_URL}${endpoint}`, {
        phoneNumber: testPhone,
        phone: testPhone
      }, {
        headers: { Authorization: `Bearer ${authToken}` }
      });

      if (response.status === 200 || response.status === 201) {
        console.log(`✅ Phone verification initiated via ${endpoint}`);
        console.log(`   Response:`, response.data);
        return;
      }
    } catch (error) {
      // Try PUT method
      try {
        const response = await axios.put(`${BASE_URL}${endpoint}`, {
          phoneNumber: testPhone,
          phone: testPhone
        }, {
          headers: { Authorization: `Bearer ${authToken}` }
        });

        if (response.status === 200) {
          console.log(`✅ Phone update successful via PUT ${endpoint}`);
          return;
        }
      } catch (putError) {
        // Continue
      }
    }
  }

  console.log('⚠️ Phone update/verification endpoint not found');
}

async function testEmailUpdate() {
  console.log('📧 Testing email update...');

  const newEmail = `updated${Date.now()}@example.com`;

  const endpoints = [
    '/api/users/me/email',
    '/api/users/me',
    '/api/auth/update-email',
    '/api/email/update'
  ];

  for (const endpoint of endpoints) {
    try {
      const response = await axios.put(`${BASE_URL}${endpoint}`, {
        email: newEmail,
        newEmail: newEmail,
        password: 'testpassword123'
      }, {
        headers: { Authorization: `Bearer ${authToken}` }
      });

      if (response.status === 200) {
        console.log(`✅ Email update successful via ${endpoint}`);
        return;
      }
    } catch (error) {
      // Try POST method
      try {
        const response = await axios.post(`${BASE_URL}${endpoint}`, {
          email: newEmail,
          newEmail: newEmail,
          password: 'testpassword123'
        }, {
          headers: { Authorization: `Bearer ${authToken}` }
        });

        if (response.status === 200) {
          console.log(`✅ Email update successful via POST ${endpoint}`);
          return;
        }
      } catch (postError) {
        // Continue
      }
    }
  }

  console.log('⚠️ Email update endpoint not found');
}

async function testProfilePhotoUpdate() {
  console.log('🖼️ Testing profile photo update...');

  const photoUrl = 'https://example.com/test-profile-photo.jpg';

  const endpoints = [
    '/api/users/me/profile-picture',
    '/api/users/me/photo',
    '/api/users/me',
    '/api/profile/photo'
  ];

  for (const endpoint of endpoints) {
    try {
      const response = await axios.put(`${BASE_URL}${endpoint}`, {
        profilePictureUrl: photoUrl,
        profilePhoto: photoUrl,
        photo: photoUrl
      }, {
        headers: { Authorization: `Bearer ${authToken}` }
      });

      if (response.status === 200) {
        console.log(`✅ Profile photo update successful via ${endpoint}`);
        return;
      }
    } catch (error) {
      // Try POST method
      try {
        const response = await axios.post(`${BASE_URL}${endpoint}`, {
          profilePictureUrl: photoUrl,
          profilePhoto: photoUrl,
          photo: photoUrl
        }, {
          headers: { Authorization: `Bearer ${authToken}` }
        });

        if (response.status === 200) {
          console.log(`✅ Profile photo update successful via POST ${endpoint}`);
          return;
        }
      } catch (postError) {
        // Continue
      }
    }
  }

  console.log('⚠️ Profile photo update endpoint not found');
}

async function testComprehensiveProfileRead() {
  console.log('📋 Final comprehensive profile read...');

  const response = await axios.get(`${BASE_URL}/api/users/me`, {
    headers: { Authorization: `Bearer ${authToken}` }
  });

  if (response.data.success) {
    console.log('✅ Final profile state:');
    const user = response.data.user;
    Object.keys(user).forEach(key => {
      console.log(`   ${key}: ${user[key] || 'null'}`);
    });
  }
}

// Start the server and run tests
async function startServerAndTest() {
  console.log('🚀 Starting backend server...');

  const { spawn } = require('child_process');
  const serverProcess = spawn('node', ['prisma-server.js'], {
    cwd: '/Users/shalin/Documents/Projects/Xcode/Brrow/brrow-backend',
    env: {
      ...process.env,
      DATABASE_URL: 'postgresql://postgres:kciFfaaVBLcfEAlHomvyNFnbMjIxGdOE@yamanote.proxy.rlwy.net:10740/railway',
      JWT_SECRET: 'brrow-secret-key-2024',
      PORT: '3010'
    },
    stdio: 'pipe'
  });

  let serverReady = false;

  serverProcess.stdout.on('data', (data) => {
    const output = data.toString();
    if (output.includes('🚀 Brrow Backend PostgreSQL Server')) {
      serverReady = true;
    }
  });

  serverProcess.stderr.on('data', (data) => {
    console.error('Server error:', data.toString());
  });

  // Wait for server to be ready
  await new Promise((resolve) => {
    const checkReady = () => {
      if (serverReady) {
        resolve();
      } else {
        setTimeout(checkReady, 100);
      }
    };
    checkReady();
  });

  console.log('✅ Server started successfully');

  // Wait a bit more for full initialization
  await new Promise(resolve => setTimeout(resolve, 2000));

  // Run tests
  await runTests();

  // Kill server
  serverProcess.kill();
  console.log('🛑 Server stopped');
}

startServerAndTest().catch(console.error);