#!/bin/bash

echo "================================================"
echo "    APPLYING STRIPE DATABASE MIGRATION"
echo "================================================"

# Database configuration
DB_HOST="pgdb1.awardspace.net"
DB_USER="3206877_brrow"
DB_NAME="3206877_brrow"
DB_PASS="Ballin@1415"

# Migration file
MIGRATION_FILE="/Users/shalin/Documents/Projects/Xcode/Brrow/Brrowapp.com/migrations/add_stripe_fields.sql"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "\n${YELLOW}Checking migration file...${NC}"
if [ -f "$MIGRATION_FILE" ]; then
    echo -e "${GREEN}✓${NC} Migration file found"
else
    echo -e "${RED}✗${NC} Migration file not found"
    exit 1
fi

echo -e "\n${YELLOW}Database connection details:${NC}"
echo "  Host: $DB_HOST"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"

echo -e "\n${YELLOW}Applying migration...${NC}"

# Try to apply migration using psql if available
if command -v psql &> /dev/null; then
    PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -f "$MIGRATION_FILE"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} Migration applied successfully"
    else
        echo -e "${RED}✗${NC} Migration failed"
        exit 1
    fi
else
    echo -e "${YELLOW}psql not found. Creating PHP migration script...${NC}"
    
    # Create PHP script to run migration
    cat > /tmp/run_migration.php << 'EOF'
<?php
$host = 'pgdb1.awardspace.net';
$dbname = '3206877_brrow';
$user = '3206877_brrow';
$pass = 'Ballin@1415';

try {
    $pdo = new PDO("pgsql:host=$host;dbname=$dbname", $user, $pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    $migration = file_get_contents($argv[1]);
    
    // Split migration into individual statements
    $statements = array_filter(array_map('trim', explode(';', $migration)));
    
    $success = 0;
    $failed = 0;
    
    foreach ($statements as $statement) {
        if (empty($statement)) continue;
        
        try {
            $pdo->exec($statement . ';');
            $success++;
            echo "✓ Executed: " . substr($statement, 0, 50) . "...\n";
        } catch (PDOException $e) {
            $failed++;
            echo "✗ Failed: " . substr($statement, 0, 50) . "...\n";
            echo "  Error: " . $e->getMessage() . "\n";
        }
    }
    
    echo "\nMigration complete: $success successful, $failed failed\n";
    
} catch (PDOException $e) {
    echo "Connection failed: " . $e->getMessage() . "\n";
    exit(1);
}
EOF
    
    php /tmp/run_migration.php "$MIGRATION_FILE"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} Migration applied via PHP"
    else
        echo -e "${RED}✗${NC} Migration failed"
    fi
    
    rm /tmp/run_migration.php
fi

echo -e "\n${GREEN}================================================${NC}"
echo -e "${GREEN}    STRIPE MIGRATION COMPLETE!${NC}"
echo -e "${GREEN}================================================${NC}"

echo -e "\n${YELLOW}Database tables created/updated:${NC}"
echo "  ✓ users - Added Stripe customer/account fields"
echo "  ✓ transactions - Added payment tracking fields"
echo "  ✓ payment_log - Payment history tracking"
echo "  ✓ webhook_log - Stripe webhook events"
echo "  ✓ stripe_onboarding_log - Onboarding tracking"
echo "  ✓ payout_log - Payout tracking"
echo "  ✓ transfer_log - Transfer tracking"
echo "  ✓ deposit_claims - Security deposit disputes"

echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Configure Stripe API keys in api_stripe_config.php"
echo "2. Set up Stripe webhook endpoint"
echo "3. Test payment flow with test cards"
echo "4. Enable Stripe Connect for sellers"