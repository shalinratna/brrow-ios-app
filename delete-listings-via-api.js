#!/usr/bin/env node

// Script to delete all listings via the Railway API
const API_URL = 'https://brrow-backend-nodejs-production.up.railway.app';

async function deleteAllListings() {
  try {
    console.log('🔄 Fetching all listings...');

    // First, get all listings
    const response = await fetch(`${API_URL}/api/listings`);
    const data = await response.json();

    if (!data.success || !data.data) {
      console.log('❌ Failed to fetch listings');
      console.log('Response:', data);
      return;
    }

    const listings = data.data.listings || [];
    console.log(`📊 Found ${listings.length} listings to delete\n`);

    if (listings.length === 0) {
      console.log('✅ No listings to delete - database is clean!');
      return;
    }

    // Since we don't have admin authentication, we'll need to log which listings exist
    console.log('⚠️  Note: Deletion requires authentication. Here are the listings that need to be deleted:\n');

    for (const listing of listings) {
      console.log(`  📦 ${listing.title} (ID: ${listing.id})`);
      console.log(`     Owner: ${listing.owner?.username || 'Unknown'}`);
      console.log(`     Price: $${listing.dailyRate}/day`);
      console.log(`     Created: ${new Date(listing.createdAt).toLocaleDateString()}\n`);
    }

    console.log('To delete these listings, you would need to:');
    console.log('1. Log in as each listing owner');
    console.log('2. Use the DELETE /api/listings/:id endpoint');
    console.log('3. Or implement an admin endpoint to delete all listings');

  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

// Run the script
console.log('=================================');
console.log('  LISTING CHECK VIA API');
console.log('=================================\n');
deleteAllListings();