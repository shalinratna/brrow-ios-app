#!/bin/bash

echo "Detecting hosting environment for brrowapp.com..."
echo "================================================"
echo

# Check server headers
echo "Server Headers:"
curl -sI "https://brrowapp.com" | grep -i "server:" || echo "No server header found"
echo

# Check for common hosting indicators
echo "Checking for hosting indicators..."

# Check for cPanel
curl -s "https://brrowapp.com:2082" --connect-timeout 2 > /dev/null 2>&1 && echo "✓ Possible cPanel hosting (port 2082 responds)" || echo "✗ No cPanel detected on port 2082"
curl -s "https://brrowapp.com/cpanel" --connect-timeout 2 > /dev/null 2>&1 && echo "✓ Possible cPanel hosting (/cpanel exists)" || echo "✗ No /cpanel path"

# Check for Plesk
curl -s "https://brrowapp.com:8443" --connect-timeout 2 > /dev/null 2>&1 && echo "✓ Possible Plesk hosting (port 8443 responds)" || echo "✗ No Plesk detected on port 8443"

# Check common paths
echo
echo "Checking common hosting paths..."
paths=("/cgi-bin/php" "/cgi-bin/php5" "/cgi-bin/php7" "/cgi-bin/php8")
for path in "${paths[@]}"; do
    response=$(curl -s -o /dev/null -w "%{http_code}" "https://brrowapp.com$path" --connect-timeout 2)
    if [ "$response" != "404" ] && [ "$response" != "000" ]; then
        echo "✓ Found: $path (HTTP $response)"
    fi
done

# DNS lookup
echo
echo "DNS Information:"
nslookup brrowapp.com | grep -A1 "Name:" || echo "DNS lookup failed"

# Try to detect PHP info from headers
echo
echo "Checking PHP response headers..."
curl -sI "https://brrowapp.com/test_php_execution.php" | grep -i "x-powered-by" || echo "No X-Powered-By header"

echo
echo "================================================"
echo "RECOMMENDED ACTIONS BASED ON HOSTING TYPE:"
echo
echo "1. If AwardSpace hosting (common for .com sites):"
echo "   - Login to AwardSpace control panel"
echo "   - Go to 'Website Settings' or 'PHP Settings'"
echo "   - Ensure PHP is enabled for the domain"
echo "   - Select PHP version 7.4 or higher"
echo
echo "2. If shared hosting without control panel:"
echo "   - Contact support immediately"
echo "   - Request PHP handler activation"
echo "   - Mention it's urgent for app launch"
echo
echo "3. Upload the correct .htaccess for your hosting type"
echo "================================================"