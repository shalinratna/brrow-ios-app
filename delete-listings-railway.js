#!/usr/bin/env node

// Direct database deletion using Railway PostgreSQL
const { Client } = require('pg');

// Railway PostgreSQL connection
const client = new Client({
  host: 'yamanote.proxy.rlwy.net',
  port: 10740,
  database: 'railway',
  user: 'postgres',
  password: 'kciFfaaVBLcfEAlHomvyNFnbMjIxGdOE' // From Railway console
});

async function deleteAllListings() {
  try {
    console.log('🔄 Connecting to Railway PostgreSQL database...');
    await client.connect();
    console.log('✅ Connected successfully!');

    // Get count before deletion (table names are lowercase in Railway)
    const countResult = await client.query('SELECT COUNT(*) FROM listings');
    const beforeCount = parseInt(countResult.rows[0].count);
    console.log(`\n📊 Found ${beforeCount} listings to delete`);

    if (beforeCount === 0) {
      console.log('✅ Database already clean - no listings to delete');
      return;
    }

    console.log('\n🗑️ Deleting related data...');

    // Delete in correct order due to foreign key constraints (lowercase table names)
    const queries = [
      { name: 'listing images', query: 'DELETE FROM listing_images' },
      { name: 'listing videos', query: 'DELETE FROM listing_videos' },
      { name: 'favorites', query: 'DELETE FROM favorites' },
      { name: 'offers', query: 'DELETE FROM offers' },
      { name: 'transactions', query: 'DELETE FROM transactions' },
      { name: 'listing reviews', query: 'DELETE FROM reviews WHERE listing_id IS NOT NULL' },
      { name: 'listings', query: 'DELETE FROM listings' }
    ];

    for (const { name, query } of queries) {
      try {
        const result = await client.query(query);
        console.log(`  ✓ Deleted ${result.rowCount} ${name}`);
      } catch (error) {
        if (error.message.includes('does not exist')) {
          console.log(`  ⚠️ Skipped ${name} (table doesn't exist)`);
        } else {
          throw error;
        }
      }
    }

    // Verify deletion
    const afterResult = await client.query('SELECT COUNT(*) FROM listings');
    const afterCount = parseInt(afterResult.rows[0].count);

    console.log(`\n✅ Successfully deleted all listings!`);
    console.log(`📊 Remaining listings: ${afterCount}`);

    if (afterCount === 0) {
      console.log('\n🎉 Database cleaned successfully!');
    }

  } catch (error) {
    console.error('\n❌ Error:', error.message);
    if (error.code === 'ECONNREFUSED') {
      console.log('Could not connect to Railway database. Check connection details.');
    }
  } finally {
    await client.end();
  }
}

// Run the deletion
console.log('=================================');
console.log('  RAILWAY DATABASE DELETION');
console.log('=================================\n');
console.log('⚠️  WARNING: This will delete ALL listings from Railway database!');
console.log('Starting in 3 seconds... (Press Ctrl+C to cancel)\n');

setTimeout(() => {
  deleteAllListings();
}, 3000);