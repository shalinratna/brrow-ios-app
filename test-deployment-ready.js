#!/usr/bin/env node

const axios = require('axios');

// Configuration
const BASE_URL = 'http://localhost:3010';
const TEST_EMAIL = `deploy${Date.now()}@example.com`;
const TEST_USERNAME = `deployuser${Date.now()}`;

let authToken = '';
let userId = '';

console.log('🚀 DEPLOYMENT READINESS TEST');
console.log('===========================');

async function runDeploymentTest() {
  try {
    console.log('\n1️⃣ USER REGISTRATION TEST');
    await testUserRegistration();

    console.log('\n2️⃣ PROFILE UPDATE TEST (FIXED ROUTING)');
    await testProfileUpdate();

    console.log('\n3️⃣ BIO UPDATE TEST');
    await testBioUpdate();

    console.log('\n4️⃣ PHONE UPDATE TEST');
    await testPhoneUpdate();

    console.log('\n5️⃣ EMAIL UPDATE TEST');
    await testEmailUpdate();

    console.log('\n6️⃣ COMPREHENSIVE VALIDATION');
    await validateAllEndpoints();

    console.log('\n✅ DEPLOYMENT READINESS CONFIRMED');
    console.log('=================================');

  } catch (error) {
    console.error('❌ Deployment test failed:', error.message);
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Data:', JSON.stringify(error.response.data, null, 2));
    }
  }
}

async function testUserRegistration() {
  const response = await axios.post(`${BASE_URL}/api/auth/register`, {
    email: TEST_EMAIL,
    password: 'testpassword123',
    username: TEST_USERNAME,
    firstName: 'Deploy',
    lastName: 'Test'
  });

  if (response.data.success) {
    authToken = response.data.accessToken;
    userId = response.data.user.id;
    console.log('✅ Registration works');
  } else {
    throw new Error('Registration failed');
  }
}

async function testProfileUpdate() {
  const response = await axios.put(`${BASE_URL}/api/users/me`, {
    firstName: 'DeployFixed',
    lastName: 'TestFixed',
    bio: 'Updated bio after routing fix',
    location: 'Production Ready'
  }, {
    headers: { Authorization: `Bearer ${authToken}` }
  });

  if (response.data.success) {
    console.log('✅ Profile update works');
    console.log(`   Name: ${response.data.user.firstName} ${response.data.user.lastName}`);
    console.log(`   Bio: ${response.data.user.bio}`);
  } else {
    throw new Error('Profile update failed');
  }
}

async function testBioUpdate() {
  const response = await axios.put(`${BASE_URL}/api/users/me/bio`, {
    bio: 'Bio updated via dedicated endpoint'
  }, {
    headers: { Authorization: `Bearer ${authToken}` }
  });

  if (response.data.success) {
    console.log('✅ Bio update works');
    console.log(`   Bio: ${response.data.user.bio}`);
  } else {
    throw new Error('Bio update failed');
  }
}

async function testPhoneUpdate() {
  const response = await axios.put(`${BASE_URL}/api/users/me/phone`, {
    phoneNumber: '+15551234567'
  }, {
    headers: { Authorization: `Bearer ${authToken}` }
  });

  if (response.data.success) {
    console.log('✅ Phone update works');
    console.log(`   Phone: ${response.data.user.phoneNumber}`);
  } else {
    throw new Error('Phone update failed');
  }
}

async function testEmailUpdate() {
  const newEmail = `updated${Date.now()}@example.com`;
  const response = await axios.put(`${BASE_URL}/api/users/me/email`, {
    newEmail: newEmail
  }, {
    headers: { Authorization: `Bearer ${authToken}` }
  });

  if (response.data.success) {
    console.log('✅ Email update works');
    console.log(`   Email: ${response.data.user.email}`);
  } else {
    throw new Error('Email update failed');
  }
}

async function validateAllEndpoints() {
  const endpoints = [
    { method: 'GET', url: '/api/users/me', description: 'Profile Read' },
    { method: 'PUT', url: '/api/users/me', description: 'Profile Update' },
    { method: 'PUT', url: '/api/users/me/bio', description: 'Bio Update' },
    { method: 'PUT', url: '/api/users/me/phone', description: 'Phone Update' },
    { method: 'PUT', url: '/api/users/me/email', description: 'Email Update' },
    { method: 'PUT', url: '/api/users/me/profile-picture', description: 'Photo Update' }
  ];

  console.log('📋 Endpoint Validation:');

  for (const endpoint of endpoints) {
    try {
      let response;
      const config = { headers: { Authorization: `Bearer ${authToken}` } };

      if (endpoint.method === 'GET') {
        response = await axios.get(`${BASE_URL}${endpoint.url}`, config);
      } else {
        const testData = {
          bio: 'test',
          phoneNumber: '+15551234567',
          newEmail: 'test@example.com',
          profilePictureUrl: 'https://example.com/test.jpg'
        };
        response = await axios.put(`${BASE_URL}${endpoint.url}`, testData, config);
      }

      console.log(`   ✅ ${endpoint.description}: ${response.status}`);
    } catch (error) {
      console.log(`   ❌ ${endpoint.description}: ${error.response?.status || 'Failed'}`);
    }
  }
}

// Start server and test
async function startAndTest() {
  console.log('🚀 Starting server for deployment test...');

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

  // Wait for server
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

  console.log('✅ Server ready');

  // Wait for full initialization
  await new Promise(resolve => setTimeout(resolve, 2000));

  // Run tests
  await runDeploymentTest();

  // Stop server
  serverProcess.kill();
  console.log('🛑 Server stopped');
}

startAndTest().catch(console.error);