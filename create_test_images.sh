#!/bin/bash

# Create test images for the listing
LISTING_ID="lst_68b497352f565.94968638"
UPLOAD_DIR="/Users/shalin/Documents/Projects/Xcode/Brrow/Brrowapp.com/uploads/listings/$LISTING_ID"

echo "Creating test images directory: $UPLOAD_DIR"
mkdir -p "$UPLOAD_DIR"

# Download sample images from placeholder service
for i in {01..07}; do
    IMAGE_NAME="listing_${LISTING_ID}_20250831184053_${i}.jpg"
    echo "Creating image: $IMAGE_NAME"
    
    # Use curl to download a placeholder image
    curl -L -s "https://via.placeholder.com/800x600/4285F4/FFFFFF?text=Image+${i}" \
         -o "$UPLOAD_DIR/$IMAGE_NAME"
done

echo "Test images created in: $UPLOAD_DIR"
ls -la "$UPLOAD_DIR"