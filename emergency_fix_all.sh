#!/bin/bash

echo "========================================================"
echo "EMERGENCY: FIXING PHP EXECUTION - RELEASE TOMORROW!"
echo "Testing all possible .htaccess configurations..."
echo "========================================================"
echo

configs=(
    ".htaccess.awardspace"
    ".htaccess.cloudflare" 
    ".htaccess.cpanel"
    ".htaccess.plesk"
    ".htaccess.emergency"
)

for config in "${configs[@]}"; do
    echo "Testing: $config"
    
    # Copy config
    cp "Brrowapp.com/$config" "Brrowapp.com/.htaccess" 2>/dev/null
    
    # Wait for propagation
    sleep 3
    
    # Test PHP execution
    response=$(curl -s "https://brrowapp.com/test_php_execution.php" --connect-timeout 10 | head -1)
    
    if [[ "$response" == "{"* ]] || [[ "$response" == *"success"* ]]; then
        echo "✅ SUCCESS! PHP is executing with: $config"
        echo "Response: $response"
        echo
        echo "This configuration is working! Keeping it..."
        
        # Test API endpoint
        api_response=$(curl -s -H "User-Agent: BrrowApp-iOS/1.0" "https://brrowapp.com/brrow/api/fetch_listings.php?page=1&per_page=1" --connect-timeout 10 | head -1)
        
        if [[ "$api_response" == "{"* ]]; then
            echo "✅ API is also working!"
            echo "API Response: ${api_response:0:50}..."
        else
            echo "⚠️  API might have issues: ${api_response:0:50}..."
        fi
        
        exit 0
    else
        echo "❌ Failed: ${response:0:50}..."
    fi
    echo
done

echo "========================================================"
echo "❌ CRITICAL: NO CONFIGURATION WORKED!"
echo ""
echo "IMMEDIATE ACTIONS REQUIRED:"
echo ""
echo "1. CONTACT HOSTING SUPPORT RIGHT NOW:"
echo "   Message: 'URGENT: PHP not executing on brrowapp.com"
echo "   Files showing source code instead of running."
echo "   Need PHP handler enabled immediately - app launches tomorrow!'"
echo ""
echo "2. CHECK HOSTING CONTROL PANEL:"
echo "   - Look for 'PHP Version' or 'PHP Settings'"
echo "   - Ensure PHP is enabled (not disabled)"
echo "   - Try different PHP versions (7.4, 8.0, 8.1)"
echo ""
echo "3. ALTERNATIVE HOSTING (if urgent):"
echo "   - DigitalOcean App Platform (quick deploy)"
echo "   - Heroku with PHP buildpack"
echo "   - AWS Elastic Beanstalk"
echo "   - Shared hosting with guaranteed PHP (SiteGround, Bluehost)"
echo ""
echo "4. TEMPORARY MEASURE:"
echo "   Block all PHP files to prevent source code exposure:"
echo "   cp Brrowapp.com/.htaccess.block_php Brrowapp.com/.htaccess"
echo ""
echo "========================================================"
echo "After hosting provider fixes, test with: ./test_api_response.sh"
echo "========================================================"