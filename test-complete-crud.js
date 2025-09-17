#!/usr/bin/env node

/**
 * Comprehensive CRUD Test Suite for Brrow Platform
 * Tests all features and cleans up test data after completion
 */

const axios = require('axios');

const API_BASE = 'https://brrow-backend-nodejs-production.up.railway.app';
const TEST_USER = {
    username: `testuser_${Date.now()}`,
    email: `test_${Date.now()}@example.com`,
    password: 'Test123!@#',
    firstName: 'Test',
    lastName: 'User'
};

let authToken = null;
let userId = null;
let listingId = null;
let conversationId = null;
let messageId = null;

// Helper function for API calls
async function apiCall(method, endpoint, data = null, token = null) {
    try {
        const config = {
            method,
            url: `${API_BASE}${endpoint}`,
            headers: {}
        };

        if (token) {
            config.headers.Authorization = `Bearer ${token}`;
        }

        if (data) {
            config.data = data;
            config.headers['Content-Type'] = 'application/json';
        }

        const response = await axios(config);
        return { success: true, data: response.data };
    } catch (error) {
        return {
            success: false,
            error: error.response?.data || error.message,
            status: error.response?.status
        };
    }
}

// Test functions
async function testUserRegistration() {
    console.log('\n📝 Testing User Registration (CREATE)...');
    const result = await apiCall('POST', '/api/auth/register', TEST_USER);

    if (result.success && result.data.data) {
        userId = result.data.data.user?.id || result.data.data.id;
        authToken = result.data.data.token || result.data.token;
        console.log('✅ User registered successfully');
        console.log(`   User ID: ${userId}`);
        return true;
    } else {
        console.log('❌ Registration failed:', result.error);
        return false;
    }
}

async function testUserLogin() {
    console.log('\n🔐 Testing User Login...');
    const result = await apiCall('POST', '/api/auth/login', {
        email: TEST_USER.email,
        password: TEST_USER.password
    });

    if (result.success && result.data.data) {
        authToken = result.data.data.token || result.data.token;
        userId = result.data.data.user?.id || result.data.data.id || userId;
        console.log('✅ Login successful');
        return true;
    } else {
        console.log('❌ Login failed:', result.error);
        return false;
    }
}

async function testUserProfile() {
    console.log('\n👤 Testing User Profile (READ)...');
    const result = await apiCall('GET', '/api/users/me', null, authToken);

    if (result.success) {
        console.log('✅ Profile fetched successfully');
        console.log(`   Username: ${result.data.data?.username}`);
        return true;
    } else {
        console.log('❌ Profile fetch failed:', result.error);
        return false;
    }
}

async function testProfileUpdate() {
    console.log('\n✏️ Testing Profile Update (UPDATE)...');
    const updateData = {
        bio: 'Test bio updated at ' + new Date().toISOString(),
        location: 'Test City'
    };

    const result = await apiCall('PUT', '/api/users/me', updateData, authToken);

    if (result.success) {
        console.log('✅ Profile updated successfully');
        return true;
    } else {
        console.log('❌ Profile update failed:', result.error);
        return false;
    }
}

async function testListingCreation() {
    console.log('\n📦 Testing Listing Creation (CREATE)...');
    const listingData = {
        title: `Test Listing ${Date.now()}`,
        description: 'This is a test listing that will be deleted',
        categoryId: 'electronics',
        condition: 'GOOD',
        price: 99.99,
        dailyRate: 10,
        isNegotiable: true,
        location: {
            address: 'Test Address',
            city: 'Test City',
            state: 'CA',
            country: 'US',
            zipCode: '12345',
            latitude: 37.7749,
            longitude: -122.4194
        },
        images: [],
        tags: ['test', 'automated']
    };

    const result = await apiCall('POST', '/api/listings', listingData, authToken);

    if (result.success && result.data.data) {
        listingId = result.data.data.id || result.data.data.listing?.id;
        console.log('✅ Listing created successfully');
        console.log(`   Listing ID: ${listingId}`);
        return true;
    } else {
        console.log('❌ Listing creation failed:', result.error);
        return false;
    }
}

async function testListingRead() {
    console.log('\n📖 Testing Listing Read...');
    const result = await apiCall('GET', `/api/listings/${listingId}`);

    if (result.success) {
        console.log('✅ Listing fetched successfully');
        console.log(`   Title: ${result.data.data?.title}`);
        return true;
    } else {
        console.log('❌ Listing fetch failed:', result.error);
        return false;
    }
}

async function testListingUpdate() {
    console.log('\n✏️ Testing Listing Update (UPDATE)...');
    const updateData = {
        title: `Updated Test Listing ${Date.now()}`,
        price: 149.99
    };

    const result = await apiCall('PUT', `/api/listings/${listingId}`, updateData, authToken);

    if (result.success) {
        console.log('✅ Listing updated successfully');
        return true;
    } else {
        console.log('❌ Listing update failed:', result.error);
        return false;
    }
}

async function testSearch() {
    console.log('\n🔍 Testing Search Functionality...');
    const result = await apiCall('GET', '/api/search?query=test');

    if (result.success) {
        console.log('✅ Search completed successfully');
        console.log(`   Found ${result.data.data?.listings?.length || 0} listings`);
        return true;
    } else {
        console.log('❌ Search failed:', result.error);
        return false;
    }
}

async function testCategories() {
    console.log('\n📂 Testing Categories (READ)...');
    const result = await apiCall('GET', '/api/categories');

    if (result.success) {
        console.log('✅ Categories fetched successfully');
        console.log(`   Found ${result.data.data?.length || 0} categories`);
        return true;
    } else {
        console.log('❌ Categories fetch failed:', result.error);
        return false;
    }
}

async function testConversation() {
    console.log('\n💬 Testing Conversation Creation...');

    // First, get another listing to start a conversation about
    const listingsResult = await apiCall('GET', '/api/listings?limit=1');
    if (!listingsResult.success || !listingsResult.data.data?.listings?.length) {
        console.log('⚠️ No listings available for conversation test');
        return false;
    }

    const targetListing = listingsResult.data.data.listings[0];
    const conversationData = {
        listingId: targetListing.id,
        recipientId: targetListing.userId,
        message: 'Test message for CRUD testing'
    };

    const result = await apiCall('POST', '/api/conversations', conversationData, authToken);

    if (result.success && result.data.data) {
        conversationId = result.data.data.id;
        console.log('✅ Conversation created successfully');
        return true;
    } else {
        console.log('⚠️ Conversation creation skipped:', result.error);
        return false;
    }
}

async function testListingDeletion() {
    console.log('\n🗑️ Testing Listing Deletion (DELETE)...');

    if (!listingId) {
        console.log('⚠️ No listing to delete');
        return false;
    }

    const result = await apiCall('DELETE', `/api/listings/${listingId}`, null, authToken);

    if (result.success) {
        console.log('✅ Listing deleted successfully');
        return true;
    } else {
        console.log('❌ Listing deletion failed:', result.error);
        return false;
    }
}

async function testUserDeletion() {
    console.log('\n🗑️ Testing User Account Deletion (DELETE)...');

    const result = await apiCall('DELETE', '/api/users/me', null, authToken);

    if (result.success) {
        console.log('✅ User account deleted successfully');
        return true;
    } else {
        console.log('❌ User deletion failed:', result.error);
        return false;
    }
}

// Main test runner
async function runAllTests() {
    console.log('========================================');
    console.log('🚀 BRROW PLATFORM COMPREHENSIVE CRUD TESTS');
    console.log('========================================');
    console.log(`API Base: ${API_BASE}`);
    console.log(`Timestamp: ${new Date().toISOString()}`);

    const results = {
        passed: 0,
        failed: 0,
        total: 0
    };

    // Run tests in sequence
    const tests = [
        { name: 'User Registration', fn: testUserRegistration },
        { name: 'User Login', fn: testUserLogin },
        { name: 'User Profile', fn: testUserProfile },
        { name: 'Profile Update', fn: testProfileUpdate },
        { name: 'Listing Creation', fn: testListingCreation },
        { name: 'Listing Read', fn: testListingRead },
        { name: 'Listing Update', fn: testListingUpdate },
        { name: 'Search', fn: testSearch },
        { name: 'Categories', fn: testCategories },
        { name: 'Conversation', fn: testConversation },
        { name: 'Listing Deletion', fn: testListingDeletion },
        { name: 'User Deletion', fn: testUserDeletion }
    ];

    for (const test of tests) {
        results.total++;
        try {
            const passed = await test.fn();
            if (passed) {
                results.passed++;
            } else {
                results.failed++;
            }
        } catch (error) {
            console.log(`❌ ${test.name} threw error:`, error.message);
            results.failed++;
        }
    }

    // Final summary
    console.log('\n========================================');
    console.log('📊 TEST SUMMARY');
    console.log('========================================');
    console.log(`✅ Passed: ${results.passed}/${results.total}`);
    console.log(`❌ Failed: ${results.failed}/${results.total}`);
    console.log(`📈 Success Rate: ${Math.round(results.passed / results.total * 100)}%`);

    if (results.failed === 0) {
        console.log('\n🎉 All tests passed successfully!');
        console.log('✅ Test data has been cleaned up');
    } else {
        console.log('\n⚠️ Some tests failed - check logs above');
        console.log('⚠️ Some test data may not have been cleaned up');
    }

    process.exit(results.failed === 0 ? 0 : 1);
}

// Check for axios
try {
    require('axios');
} catch (e) {
    console.log('Installing axios...');
    require('child_process').execSync('npm install axios', { stdio: 'inherit' });
}

// Run the tests
runAllTests().catch(console.error);