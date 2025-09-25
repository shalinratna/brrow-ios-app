const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function addTestImages() {
  console.log('🔍 Finding a listing to add test images to...');

  // Find a listing with no images
  const listing = await prisma.listing.findFirst({
    include: { images: true },
    where: {
      images: { none: {} }
    }
  });

  if (!listing) {
    console.log('❌ No listings found without images');
    return;
  }

  console.log('📝 Found listing:', listing.id, listing.title);
  console.log('   Current images:', listing.images.length);

  // Add 3 test images
  const testImages = [
    {
      imageUrl: 'https://brrow-backend-nodejs-production.up.railway.app/uploads/test_image_1.jpg',
      thumbnailUrl: 'https://brrow-backend-nodejs-production.up.railway.app/uploads/test_image_1.jpg',
      isPrimary: true,
      displayOrder: 1,
      width: 800,
      height: 600
    },
    {
      imageUrl: 'https://brrow-backend-nodejs-production.up.railway.app/uploads/test_image_2.jpg',
      thumbnailUrl: 'https://brrow-backend-nodejs-production.up.railway.app/uploads/test_image_2.jpg',
      isPrimary: false,
      displayOrder: 2,
      width: 800,
      height: 600
    },
    {
      imageUrl: 'https://brrow-backend-nodejs-production.up.railway.app/uploads/test_image_3.jpg',
      thumbnailUrl: 'https://brrow-backend-nodejs-production.up.railway.app/uploads/test_image_3.jpg',
      isPrimary: false,
      displayOrder: 3,
      width: 800,
      height: 600
    }
  ];

  for (let i = 0; i < testImages.length; i++) {
    const imageData = testImages[i];
    const created = await prisma.listingImage.create({
      data: {
        listingId: listing.id,
        ...imageData
      }
    });
    console.log('✅ Created image:', created.id, 'for listing:', listing.id);
  }

  // Verify images were added
  const updatedListing = await prisma.listing.findUnique({
    where: { id: listing.id },
    include: { images: true }
  });

  console.log('🎯 Updated listing now has', updatedListing.images.length, 'images');

  await prisma.$disconnect();
}

addTestImages().catch(console.error);