#!/usr/bin/env node

/**
 * Test script to verify the three critical bug fixes
 * 1. Conversations endpoint - messageType field
 * 2. Listing creation - UUID generation
 * 3. Earnings overview - nested structure
 */

const https = require('https');

const BASE_URL = 'brrow-backend-nodejs-production.up.railway.app';

// Helper to make HTTPS requests
function makeRequest(options, postData = null) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(data) });
        } catch (e) {
          resolve({ status: res.statusCode, data: data });
        }
      });
    });
    req.on('error', reject);
    if (postData) req.write(postData);
    req.end();
  });
}

async function testFixes() {
  console.log('🧪 Testing Critical Bug Fixes on Production\n');
  console.log('Production URL:', `https://${BASE_URL}\n`);
  console.log('=' .repeat(60));

  // Step 1: Login to get auth token
  console.log('\n📝 Step 1: Getting authentication token...');
  const loginData = JSON.stringify({
    email: 'test@example.com',
    password: 'TestPassword123!'
  });

  const loginOptions = {
    hostname: BASE_URL,
    path: '/api/auth/login',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': loginData.length
    }
  };

  let token;
  try {
    const loginRes = await makeRequest(loginOptions, loginData);
    console.log(`Status: ${loginRes.status}`);

    if (loginRes.data.token) {
      token = loginRes.data.token;
      console.log('✅ Login successful - Token obtained');
    } else {
      console.log('⚠️  Login response:', JSON.stringify(loginRes.data, null, 2));
      console.log('⚠️  No token - will test unauthenticated endpoints only');
    }
  } catch (error) {
    console.log('❌ Login failed:', error.message);
    console.log('⚠️  Will test unauthenticated endpoints only');
  }

  console.log('\n' + '=' .repeat(60));

  // Test 1: Conversations endpoint - check for messageType field
  console.log('\n🧪 TEST 1: Conversations Endpoint (messageType field)');
  console.log('Expected: Response should include messageType field in lastMessage');

  if (token) {
    const conversationsOptions = {
      hostname: BASE_URL,
      path: '/api/messages/chats',
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`
      }
    };

    try {
      const convRes = await makeRequest(conversationsOptions);
      console.log(`Status: ${convRes.status}`);

      if (convRes.status === 200 && convRes.data.conversations) {
        const convs = convRes.data.conversations;
        console.log(`Found ${convs.length} conversations`);

        if (convs.length > 0 && convs[0].lastMessage) {
          const lastMsg = convs[0].lastMessage;
          if ('messageType' in lastMsg) {
            console.log(`✅ FIX CONFIRMED: messageType field is present`);
            console.log(`   Value: "${lastMsg.messageType}"`);
          } else {
            console.log(`❌ FIX FAILED: messageType field is MISSING`);
            console.log(`   Fields present:`, Object.keys(lastMsg).join(', '));
          }
        } else {
          console.log('⚠️  No conversations with messages to test');
        }
      } else {
        console.log('Response:', JSON.stringify(convRes.data, null, 2));
      }
    } catch (error) {
      console.log('❌ Test failed:', error.message);
    }
  } else {
    console.log('⏭️  Skipped (requires authentication)');
  }

  console.log('\n' + '=' .repeat(60));

  // Test 2: Listing creation - UUID generation
  console.log('\n🧪 TEST 2: Listing Creation (UUID generation)');
  console.log('Expected: Should create listing without "id is missing" error');

  if (token) {
    const listingData = JSON.stringify({
      title: 'Test Listing - UUID Verification',
      description: 'Testing that UUID is auto-generated for listings',
      price: 50.00,
      category: 'Electronics',
      listingType: 'FOR-SALE',
      location: 'Test Location',
      latitude: 37.7749,
      longitude: -122.4194
    });

    const createListingOptions = {
      hostname: BASE_URL,
      path: '/api/listings',
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
        'Content-Length': listingData.length
      }
    };

    try {
      const listingRes = await makeRequest(createListingOptions, listingData);
      console.log(`Status: ${listingRes.status}`);

      if (listingRes.status === 201 && listingRes.data.listing) {
        const listing = listingRes.data.listing;
        if (listing.id) {
          console.log(`✅ FIX CONFIRMED: Listing created successfully`);
          console.log(`   Listing ID: ${listing.id}`);
          console.log(`   Title: ${listing.title}`);
        } else {
          console.log(`❌ FIX FAILED: Listing created but has no ID`);
        }
      } else if (listingRes.status >= 400) {
        const errorMsg = JSON.stringify(listingRes.data, null, 2);
        if (errorMsg.includes('id is missing') || errorMsg.includes('Argument id')) {
          console.log(`❌ FIX FAILED: Still getting "id is missing" error`);
          console.log(`   Error:`, errorMsg);
        } else {
          console.log(`⚠️  Different error:`, errorMsg);
        }
      } else {
        console.log('Response:', JSON.stringify(listingRes.data, null, 2));
      }
    } catch (error) {
      console.log('❌ Test failed:', error.message);
    }
  } else {
    console.log('⏭️  Skipped (requires authentication)');
  }

  console.log('\n' + '=' .repeat(60));

  // Test 3: Earnings overview - nested structure
  console.log('\n🧪 TEST 3: Earnings Overview (nested data structure)');
  console.log('Expected: Status 200 with data.overview, data.monthlyEarnings, etc.');

  if (token) {
    const earningsOptions = {
      hostname: BASE_URL,
      path: '/api/earnings/overview',
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`
      }
    };

    try {
      const earningsRes = await makeRequest(earningsOptions);
      console.log(`Status: ${earningsRes.status}`);

      if (earningsRes.status === 200) {
        const data = earningsRes.data;

        // Check for nested structure
        const hasCorrectStructure =
          data.data &&
          data.data.overview &&
          Array.isArray(data.data.monthlyEarnings) &&
          Array.isArray(data.data.topListings) &&
          data.data.payoutInfo;

        if (hasCorrectStructure) {
          console.log(`✅ FIX CONFIRMED: Correct nested structure`);
          console.log(`   - data.overview: ✓`);
          console.log(`   - data.monthlyEarnings: ✓`);
          console.log(`   - data.topListings: ✓`);
          console.log(`   - data.payoutInfo: ✓`);
        } else {
          console.log(`❌ FIX FAILED: Incorrect structure`);
          console.log(`   Structure:`, JSON.stringify(data, null, 2));
        }
      } else if (earningsRes.status === 500) {
        console.log(`❌ FIX FAILED: Still returning 500 error`);
        console.log(`   Response:`, JSON.stringify(earningsRes.data, null, 2));
      } else {
        console.log('Response:', JSON.stringify(earningsRes.data, null, 2));
      }
    } catch (error) {
      console.log('❌ Test failed:', error.message);
    }
  } else {
    console.log('⏭️  Skipped (requires authentication)');
  }

  console.log('\n' + '=' .repeat(60));
  console.log('\n✅ Testing Complete\n');
}

// Run tests
testFixes().catch(console.error);
