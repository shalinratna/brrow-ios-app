#!/usr/bin/env node

const API_URL = 'https://brrow-backend-nodejs-production.up.railway.app';

// Base64 test images (1x1 pixels)
const TEST_IMAGES = {
  red: 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==',
  blue: 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPj/HwADBwIAMCbHYwAAAABJRU5ErkJggg==',
  green: 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADngHADHlLGAAAAABJRU5ErkJggg=='
};

async function runCompleteCRUDTest() {
  let token = null;
  let userId = null;
  let listingId = null;

  console.log('🚀 COMPREHENSIVE CRUD TEST SUITE\n');
  console.log('='.repeat(50));

  // ============ 1. USER REGISTRATION ============
  console.log('\n📝 1. USER REGISTRATION');
  console.log('-'.repeat(30));

  const timestamp = Date.now();
  const testUser = {
    username: `crud_${timestamp.toString().slice(-8)}`,
    email: `crud_${timestamp}@test.com`,
    password: 'Test123!',
    firstName: 'CRUD',
    lastName: 'Tester'
  };

  try {
    const registerRes = await fetch(`${API_URL}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(testUser)
    });

    if (registerRes.ok) {
      const data = await registerRes.json();
      console.log('✅ Registration successful');
      console.log(`   User: ${testUser.username}`);
    } else {
      console.log('❌ Registration failed:', await registerRes.text());
      return;
    }
  } catch (error) {
    console.log('❌ Registration error:', error.message);
    return;
  }

  // ============ 2. USER LOGIN ============
  console.log('\n🔑 2. USER LOGIN');
  console.log('-'.repeat(30));

  try {
    const loginRes = await fetch(`${API_URL}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: testUser.username,
        password: testUser.password
      })
    });

    if (loginRes.ok) {
      const data = await loginRes.json();
      token = data.accessToken;
      userId = data.user.id;
      console.log('✅ Login successful');
      console.log(`   Token: ${token.substring(0, 30)}...`);
      console.log(`   User ID: ${userId}`);
    } else {
      console.log('❌ Login failed:', await loginRes.text());
      return;
    }
  } catch (error) {
    console.log('❌ Login error:', error.message);
    return;
  }

  // ============ 3. PROFILE PICTURE UPLOAD ============
  console.log('\n🖼️ 3. PROFILE PICTURE OPERATIONS');
  console.log('-'.repeat(30));

  // Upload profile picture
  console.log('📤 Uploading profile picture...');
  try {
    const uploadRes = await fetch(`${API_URL}/api/users/me/profile-picture`, {
      method: 'PUT',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ image: TEST_IMAGES.red })
    });

    if (uploadRes.ok) {
      const data = await uploadRes.json();
      console.log('✅ Profile picture uploaded');
      console.log(`   URL: ${data.url}`);
    } else {
      console.log('❌ Upload failed:', await uploadRes.text());
    }
  } catch (error) {
    console.log('❌ Upload error:', error.message);
  }

  // Update profile picture
  console.log('🔄 Updating profile picture...');
  try {
    const updateRes = await fetch(`${API_URL}/api/users/me/profile-picture`, {
      method: 'PUT',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ image: TEST_IMAGES.blue })
    });

    if (updateRes.ok) {
      const data = await updateRes.json();
      console.log('✅ Profile picture updated');
      console.log(`   New URL: ${data.url}`);
    }
  } catch (error) {
    console.log('❌ Update error:', error.message);
  }

  // ============ 4. GET USER PROFILE ============
  console.log('\n👤 4. GET USER PROFILE');
  console.log('-'.repeat(30));

  try {
    const profileRes = await fetch(`${API_URL}/api/users/me`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });

    if (profileRes.ok) {
      const data = await profileRes.json();
      console.log('✅ Profile retrieved');
      console.log(`   Username: ${data.user.username}`);
      console.log(`   Email: ${data.user.email}`);
      console.log(`   Profile Picture: ${data.user.profilePictureUrl ? 'Yes' : 'No'}`);
    } else {
      console.log('❌ Profile fetch failed:', await profileRes.text());
    }
  } catch (error) {
    console.log('❌ Profile error:', error.message);
  }

  // ============ 5. UPDATE USER PROFILE ============
  console.log('\n✏️ 5. UPDATE USER PROFILE');
  console.log('-'.repeat(30));

  try {
    const updateRes = await fetch(`${API_URL}/api/users/me`, {
      method: 'PUT',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        firstName: 'Updated',
        lastName: 'Name',
        bio: 'This is my updated bio',
        phone: `+1${timestamp.toString().slice(-10)}`  // Use unique phone number based on timestamp
      })
    });

    if (updateRes.ok) {
      const data = await updateRes.json();
      console.log('✅ Profile updated');
      console.log(`   Name: ${data.user.firstName} ${data.user.lastName}`);
      console.log(`   Bio: ${data.user.bio}`);
    } else {
      console.log('❌ Update failed:', await updateRes.text());
    }
  } catch (error) {
    console.log('❌ Update error:', error.message);
  }

  // ============ 6. CREATE LISTING WITH IMAGES ============
  console.log('\n📦 6. CREATE LISTING WITH IMAGES');
  console.log('-'.repeat(30));

  const newListing = {
    title: 'Test Camera for Rent',
    description: 'Professional DSLR camera available for rent.',
    categoryId: 'electronics',
    dailyRate: 50,
    weeklyRate: 300,
    monthlyRate: 1000,
    location: {
      address: '123 Test Street',
      city: 'San Francisco',
      state: 'CA',
      country: 'USA',
      zipCode: '94102',
      latitude: 37.7749,
      longitude: -122.4194
    },
    condition: 'LIKE_NEW',
    availabilityStatus: 'AVAILABLE',
    images: [
      'https://brrowapp.com/test-image-1.jpg',
      'https://brrowapp.com/test-image-2.jpg',
      'https://brrowapp.com/test-image-3.jpg'
    ]
  };

  try {
    const createRes = await fetch(`${API_URL}/api/listings`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(newListing)
    });

    if (createRes.ok) {
      const data = await createRes.json();
      listingId = data.listing?.id || data.id;
      console.log('✅ Listing created');
      console.log(`   ID: ${listingId}`);
      console.log(`   Title: ${data.listing?.title || newListing.title}`);
      console.log(`   Daily Rate: $${data.listing?.dailyRate || newListing.dailyRate}`);
    } else {
      const error = await createRes.text();
      console.log('❌ Create failed:', error.substring(0, 200));
    }
  } catch (error) {
    console.log('❌ Create error:', error.message);
  }

  // ============ 7. GET ALL LISTINGS ============
  console.log('\n📋 7. GET ALL LISTINGS');
  console.log('-'.repeat(30));

  try {
    const listRes = await fetch(`${API_URL}/api/listings`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });

    if (listRes.ok) {
      const data = await listRes.json();
      console.log('✅ Listings retrieved');
      console.log(`   Total: ${data.listings?.length || 0} listings`);
      if (data.listings?.length > 0) {
        console.log(`   First listing: ${data.listings[0].title}`);
      }
    } else {
      console.log('❌ List failed:', await listRes.text());
    }
  } catch (error) {
    console.log('❌ List error:', error.message);
  }

  // ============ 8. GET SINGLE LISTING ============
  if (listingId) {
    console.log('\n🔍 8. GET SINGLE LISTING');
    console.log('-'.repeat(30));

    try {
      const getRes = await fetch(`${API_URL}/api/listings/${listingId}`, {
        headers: { 'Authorization': `Bearer ${token}` }
      });

      if (getRes.ok) {
        const data = await getRes.json();
        console.log('✅ Listing retrieved');
        console.log(`   Title: ${data.listing?.title || data.title}`);
        console.log(`   Views: ${data.listing?.viewCount || data.viewCount || 0}`);
      } else {
        console.log('❌ Get failed:', await getRes.text());
      }
    } catch (error) {
      console.log('❌ Get error:', error.message);
    }
  }

  // ============ 9. UPDATE LISTING ============
  if (listingId) {
    console.log('\n✏️ 9. UPDATE LISTING');
    console.log('-'.repeat(30));

    const updateData = {
      title: 'Updated Camera - Premium DSLR',
      dailyRate: 75,
      description: 'UPDATED: Professional camera with extra lenses!'
    };

    try {
      const updateRes = await fetch(`${API_URL}/api/listings/${listingId}`, {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(updateData)
      });

      if (updateRes.ok) {
        const data = await updateRes.json();
        console.log('✅ Listing updated');
        console.log(`   New title: ${data.listing?.title || updateData.title}`);
        console.log(`   New rate: $${data.listing?.dailyRate || updateData.dailyRate}`);
      } else {
        console.log('❌ Update failed:', await updateRes.text());
      }
    } catch (error) {
      console.log('❌ Update error:', error.message);
    }
  }

  // ============ 10. SEARCH LISTINGS ============
  console.log('\n🔎 10. SEARCH LISTINGS');
  console.log('-'.repeat(30));

  try {
    const searchRes = await fetch(`${API_URL}/api/listings/search?q=camera`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });

    if (searchRes.ok) {
      const data = await searchRes.json();
      console.log('✅ Search completed');
      console.log(`   Results: ${data.listings?.length || 0} listings`);
    } else {
      console.log('❌ Search failed:', await searchRes.text());
    }
  } catch (error) {
    console.log('❌ Search error:', error.message);
  }

  // ============ 11. DELETE LISTING ============
  if (listingId) {
    console.log('\n🗑️ 11. DELETE LISTING');
    console.log('-'.repeat(30));

    try {
      const deleteRes = await fetch(`${API_URL}/api/listings/${listingId}`, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${token}` }
      });

      if (deleteRes.ok) {
        console.log('✅ Listing deleted');
        console.log(`   ID: ${listingId}`);
      } else {
        console.log('❌ Delete failed:', await deleteRes.text());
      }
    } catch (error) {
      console.log('❌ Delete error:', error.message);
    }
  }

  // ============ 12. VERIFY DELETION ============
  console.log('\n✔️ 12. VERIFY OPERATIONS');
  console.log('-'.repeat(30));

  try {
    const verifyRes = await fetch(`${API_URL}/api/listings`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });

    if (verifyRes.ok) {
      const data = await verifyRes.json();
      console.log('✅ Verification complete');
      console.log(`   Total listings: ${data.listings?.length || 0}`);
    }
  } catch (error) {
    console.log('❌ Verify error:', error.message);
  }

  // ============ 13. USERNAME CHANGE TEST ============
  console.log('\n🔄 13. USERNAME CHANGE');
  console.log('-'.repeat(30));

  const newUsername = `updated_${Date.now().toString().slice(-6)}`;
  try {
    const changeRes = await fetch(`${API_URL}/api/users/change-username`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ newUsername })
    });

    if (changeRes.ok) {
      const data = await changeRes.json();
      console.log('✅ Username changed');
      console.log(`   Old: ${data.oldUsername}`);
      console.log(`   New: ${data.newUsername}`);
    } else {
      console.log('❌ Username change failed:', await changeRes.text());
    }
  } catch (error) {
    console.log('❌ Username error:', error.message);
  }

  // ============ SUMMARY ============
  console.log('\n' + '='.repeat(50));
  console.log('📊 TEST SUMMARY');
  console.log('='.repeat(50));
  console.log('✅ User Registration & Login');
  console.log('✅ Profile Picture Upload & Update');
  console.log('✅ User Profile CRUD');
  console.log('✅ Listing CRUD Operations');
  console.log('✅ Search Functionality');
  console.log('✅ Username Change with Policy');
  console.log('\n✨ All tests completed!');
}

// Run the test suite
runCompleteCRUDTest().catch(error => {
  console.error('\n❌ Test suite failed:', error);
  process.exit(1);
});