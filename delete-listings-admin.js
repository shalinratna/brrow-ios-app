#!/usr/bin/env node

// Call the admin endpoint to delete all listings
const API_URL = 'https://brrow-backend-nodejs-production.up.railway.app';

async function deleteAllListingsAdmin() {
  try {
    console.log('🗑️  Calling admin endpoint to delete all listings...\n');

    const response = await fetch(`${API_URL}/api/admin/delete-all-listings`, {
      method: 'DELETE',
      headers: {
        'x-admin-key': 'brrow-admin-2024-delete-listings',
        'Content-Type': 'application/json'
      }
    });

    const data = await response.json();

    if (response.ok && data.success) {
      console.log('✅ Successfully deleted all listings!\n');
      console.log('📊 Deletion Summary:');
      console.log(`  • Listings deleted: ${data.deletedCounts.listings}`);
      console.log(`  • Images deleted: ${data.deletedCounts.images}`);
      console.log(`  • Videos deleted: ${data.deletedCounts.videos}`);
      console.log(`  • Favorites deleted: ${data.deletedCounts.favorites}`);
      console.log(`  • Offers deleted: ${data.deletedCounts.offers}`);
      console.log(`  • Transactions deleted: ${data.deletedCounts.transactions}`);
      console.log(`  • Reviews deleted: ${data.deletedCounts.reviews}`);
      console.log(`\n  • Remaining listings: ${data.remainingListings}`);
    } else {
      console.log('❌ Failed to delete listings');
      console.log('Response:', data);
    }

  } catch (error) {
    console.error('❌ Error calling admin endpoint:', error.message);
    console.log('\n⚠️  Note: The admin endpoint might not be deployed yet.');
    console.log('Deploy the updated server code to Railway first.');
  }
}

// Run the script
console.log('=================================');
console.log('  ADMIN LISTING DELETION');
console.log('=================================\n');
deleteAllListingsAdmin();