// Script to delete all listings via API
const fetch = require('node-fetch');

const API_URL = 'https://brrow-backend-nodejs-production.up.railway.app';

async function deleteAllListings() {
  try {
    console.log('🔄 Fetching all listings...');

    // First, get all listings
    const response = await fetch(`${API_URL}/api/listings`);
    const data = await response.json();

    if (!data.success || !data.data) {
      console.log('❌ Failed to fetch listings');
      return;
    }

    const listings = data.data.listings || [];
    console.log(`📊 Found ${listings.length} listings to delete\n`);

    if (listings.length === 0) {
      console.log('✅ No listings to delete - database is clean!');
      return;
    }

    // Delete each listing
    for (const listing of listings) {
      console.log(`🗑️  Deleting listing: ${listing.title} (ID: ${listing.id})`);

      try {
        // You'll need to add the proper auth token here
        const deleteResponse = await fetch(`${API_URL}/api/listings/${listing.id}`, {
          method: 'DELETE',
          headers: {
            'Content-Type': 'application/json',
            // Add authorization header if needed
            // 'Authorization': 'Bearer YOUR_TOKEN'
          }
        });

        if (deleteResponse.ok) {
          console.log(`   ✅ Deleted successfully`);
        } else {
          console.log(`   ❌ Failed to delete: ${deleteResponse.status}`);
        }
      } catch (error) {
        console.log(`   ❌ Error deleting: ${error.message}`);
      }
    }

    console.log('\n✅ Deletion process complete!');

  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

// Run the script
console.log('=================================');
console.log('  LISTING DELETION VIA API');
console.log('=================================\n');
deleteAllListings();