const https = require('https');

// Use a guest token or create one
const options = {
  hostname: 'brrow-backend-nodejs-production.up.railway.app',
  path: '/api/listings?limit=1',
  method: 'GET'
};

https.get(options, (res) => {
  let body = '';
  res.on('data', (chunk) => body += chunk);
  res.on('end', () => {
    const data = JSON.parse(body);
    if (data.success && data.data && data.data.listings && data.data.listings.length > 0) {
      const listing = data.data.listings[0];
      console.log('✅ Sample listing format from /api/listings:');
      console.log('  Fields present:');
      console.log('  - dailyRate (camelCase):', listing.dailyRate !== undefined ? '✓' : '✗');
      console.log('  - availabilityStatus (camelCase):', listing.availabilityStatus !== undefined ? '✓' : '✗');
      console.log('  - createdAt (camelCase):', listing.createdAt !== undefined ? '✓' : '✗');
      console.log('  - imageUrls (array):', listing.imageUrls !== undefined ? '✓' : '✗');
      console.log('\nFavorites endpoint should now match this format ✅');
    }
  });
});
