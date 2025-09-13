const fs = require('fs');
const path = require('path');

// Test image upload without auth to see the response format
async function testImageUpload() {
    const apiUrl = 'https://brrow-backend-nodejs-production.up.railway.app';

    // Create a simple test image (1x1 red pixel)
    const redPixel = Buffer.from([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
        0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, // IDAT chunk
        0x54, 0x08, 0x99, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
        0x00, 0x00, 0x03, 0x00, 0x01, 0x9A, 0x6C, 0x18,
        0x21, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, // IEND chunk
        0x44, 0xAE, 0x42, 0x60, 0x82
    ]);

    const base64Image = redPixel.toString('base64');

    try {
        console.log('Testing image upload to backend (no auth)...');
        
        const response = await fetch(`${apiUrl}/api/upload`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                image: base64Image,
                fileName: 'test-image.png',
                fileType: 'image/png',
                entity_type: 'listings',
                type: 'listing',
                media_type: 'image',
                quality: 'highest',
                preserve_metadata: true
            })
        });

        const result = await response.json();
        
        console.log('\n✅ Upload Response:');
        console.log(JSON.stringify(result, null, 2));

        if (result.success && result.data) {
            console.log('\n📸 Image uploaded successfully!');
            
            // Check all possible field names
            console.log('\n🔍 Checking response fields:');
            console.log('- url:', result.data.url || 'NOT FOUND');
            console.log('- image_url:', result.data.image_url || 'NOT FOUND');
            console.log('- imageUrl:', result.data.imageUrl || 'NOT FOUND');
            console.log('- public_id:', result.data.public_id || 'NOT FOUND');
            console.log('- publicId:', result.data.publicId || 'NOT FOUND');
            console.log('- thumbnail_url:', result.data.thumbnail_url || 'NOT FOUND');
            
            console.log('\n📊 Full data object:');
            console.log(result.data);
        } else {
            console.log('❌ Upload response:', result);
        }

    } catch (error) {
        console.error('❌ Test failed:', error);
    }
}

// Run the test
testImageUpload();