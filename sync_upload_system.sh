#!/bin/bash

echo "================================================"
echo "    SYNC IMAGE UPLOAD SYSTEM TO SERVER"
echo "================================================"
echo

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Your server details (update these if needed)
SERVER_HOST="brrowapp.com"
SERVER_PATH="/srv/disk5/3206877/www/brrowapp.com"

echo -e "${YELLOW}Files to sync:${NC}"
echo "1. /api_upload_file.php (root wrapper)"
echo "2. /brrow/includes/upload_handler.php (main logic)"
echo "3. /brrow/uploads/ directory structure"
echo

echo -e "${YELLOW}Ready to sync to $SERVER_HOST${NC}"
echo "This will:"
echo "• Upload the wrapper to the root"
echo "• Upload the handler to /brrow/includes/"
echo "• Create the /brrow/uploads/ directory structure"
echo

read -p "Do you want to continue? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Sync cancelled."
    exit 1
fi

echo
echo "Syncing files..."

# Use rsync to sync the files (dry run first)
echo -e "${YELLOW}Performing dry run...${NC}"
rsync -avzn --include='/api_upload_file.php' \
    --include='/brrow/' \
    --include='/brrow/includes/' \
    --include='/brrow/includes/upload_handler.php' \
    --include='/brrow/uploads/***' \
    --exclude='*' \
    /Users/shalin/Documents/Projects/Xcode/Brrow/Brrowapp.com/ \
    $SERVER_HOST:$SERVER_PATH/

echo
read -p "Dry run complete. Proceed with actual sync? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Sync cancelled."
    exit 1
fi

# Actual sync
echo -e "${YELLOW}Syncing files to server...${NC}"
rsync -avz --include='/api_upload_file.php' \
    --include='/brrow/' \
    --include='/brrow/includes/' \
    --include='/brrow/includes/upload_handler.php' \
    --include='/brrow/uploads/***' \
    --exclude='*' \
    /Users/shalin/Documents/Projects/Xcode/Brrow/Brrowapp.com/ \
    $SERVER_HOST:$SERVER_PATH/

if [ $? -eq 0 ]; then
    echo
    echo -e "${GREEN}✅ Files synced successfully!${NC}"
    echo
    echo "Next steps:"
    echo "1. Build and run the iOS app"
    echo "2. Create a listing with images"
    echo "3. Check if images display correctly"
else
    echo
    echo -e "${RED}❌ Sync failed. Please check your connection and try again.${NC}"
fi

echo
echo "================================================"
echo "          TESTING THE UPLOAD"
echo "================================================"
echo
echo "You can test the upload with this command:"
echo
echo "curl -X POST https://brrowapp.com/api_upload_file.php \\"
echo "  -H 'Authorization: Bearer YOUR_TOKEN' \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{"
echo '    "image": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==",'
echo '    "type": "listing"'
echo "  }'"