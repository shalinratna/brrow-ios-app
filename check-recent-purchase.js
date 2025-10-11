const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: 'postgresql://postgres:kciFfaaVBLcfEAlHomvyNFnbMjIxGdOE@yamanote.proxy.rlwy.net:10740/railway'
    }
  }
});

async function checkRecentPurchase() {
  try {
    console.log('🔍 Checking recent purchases...\n');

    // Get the most recent purchase
    const recentPurchases = await prisma.purchases.findMany({
      take: 3,
      orderBy: {
        created_at: 'desc'
      },
      select: {
        id: true,
        listing_id: true,
        buyer_id: true,
        seller_id: true,
        purchase_type: true,
        amount: true,
        payment_intent_id: true,
        payment_status: true,
        verification_status: true,
        created_at: true,
        updated_at: true
      }
    });

    if (recentPurchases.length === 0) {
      console.log('❌ No purchases found');
      return;
    }

    console.log('📊 Most Recent Purchases:\n');
    recentPurchases.forEach((purchase, index) => {
      console.log(`Purchase ${index + 1}:`);
      console.log(`  ID: ${purchase.id}`);
      console.log(`  Listing: ${purchase.listing_id}`);
      console.log(`  Buyer: ${purchase.buyer_id}`);
      console.log(`  Amount: $${purchase.amount}`);
      console.log(`  Payment Status: ${purchase.payment_status}`);
      console.log(`  Verification Status: ${purchase.verification_status}`);
      console.log(`  Payment Intent: ${purchase.payment_intent_id || 'None'}`);
      console.log(`  Created: ${purchase.created_at}`);
      console.log('');
    });

    // Check the listing status for the most recent purchase
    const mostRecent = recentPurchases[0];
    const listing = await prisma.listings.findUnique({
      where: { id: mostRecent.listing_id },
      select: {
        id: true,
        title: true,
        availability_status: true,
        listing_type: true
      }
    });

    if (listing) {
      console.log('📦 Associated Listing:');
      console.log(`  Title: ${listing.title}`);
      console.log(`  Status: ${listing.availability_status}`);
      console.log(`  Type: ${listing.listing_type}`);
    }

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

checkRecentPurchase();
