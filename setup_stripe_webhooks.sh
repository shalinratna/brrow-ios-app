#!/bin/bash

# Setup Stripe Webhooks for Brrow
echo "================================================"
echo "    CONFIGURING STRIPE WEBHOOKS"
echo "================================================"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "\n${YELLOW}Stripe Webhook Configuration Instructions${NC}"
echo "================================================"

echo -e "\n${BLUE}Step 1: Login to Stripe Dashboard${NC}"
echo "  1. Go to https://dashboard.stripe.com"
echo "  2. Sign in with your account"

echo -e "\n${BLUE}Step 2: Navigate to Webhooks${NC}"
echo "  1. Click 'Developers' in the left sidebar"
echo "  2. Click 'Webhooks'"
echo "  3. Click 'Add endpoint'"

echo -e "\n${BLUE}Step 3: Configure Webhook Endpoint${NC}"
echo "  Endpoint URL: ${GREEN}https://brrowapp.com/brrow/api_stripe_webhook.php${NC}"
echo ""
echo "  Select Events to Listen for:"
echo "  ${GREEN}✓${NC} payment_intent.succeeded"
echo "  ${GREEN}✓${NC} payment_intent.payment_failed"
echo "  ${GREEN}✓${NC} charge.succeeded"
echo "  ${GREEN}✓${NC} charge.failed"
echo "  ${GREEN}✓${NC} charge.refunded"
echo "  ${GREEN}✓${NC} account.updated (for Connect accounts)"
echo "  ${GREEN}✓${NC} account.application.authorized"
echo "  ${GREEN}✓${NC} account.application.deauthorized"
echo "  ${GREEN}✓${NC} transfer.created"
echo "  ${GREEN}✓${NC} transfer.reversed"
echo "  ${GREEN}✓${NC} payout.created"
echo "  ${GREEN}✓${NC} payout.paid"
echo "  ${GREEN}✓${NC} payout.failed"
echo "  ${GREEN}✓${NC} customer.subscription.created"
echo "  ${GREEN}✓${NC} customer.subscription.updated"
echo "  ${GREEN}✓${NC} customer.subscription.deleted"

echo -e "\n${BLUE}Step 4: Get Webhook Secret${NC}"
echo "  After creating the webhook:"
echo "  1. Click on the webhook you just created"
echo "  2. Copy the 'Signing secret' (starts with whsec_)"
echo "  3. Save it for the next step"

echo -e "\n${BLUE}Step 5: Update Configuration File${NC}"
echo "  Update the webhook secret in your configuration:"
echo ""

# Create update script for webhook secret
cat > /tmp/update_webhook_secret.php << 'EOF'
<?php
// Update this with your actual webhook secret
$webhook_secret = 'whsec_YOUR_WEBHOOK_SECRET_HERE';

// Path to config file
$config_file = '/Users/shalin/Documents/Projects/Xcode/Brrow/Brrowapp.com/api_stripe_config.php';

// Read the file
$content = file_get_contents($config_file);

// Replace the webhook secret
$content = preg_replace(
    "/define\('STRIPE_WEBHOOK_SECRET', '.*?'\)/",
    "define('STRIPE_WEBHOOK_SECRET', '$webhook_secret')",
    $content
);

// Write back
file_put_contents($config_file, $content);

echo "Webhook secret updated successfully!\n";
?>
EOF

echo "  Run this command after getting your webhook secret:"
echo -e "  ${GREEN}php /tmp/update_webhook_secret.php${NC}"

echo -e "\n${BLUE}Step 6: Test Webhook${NC}"
echo "  1. In Stripe Dashboard, click 'Send test webhook'"
echo "  2. Select 'payment_intent.succeeded'"
echo "  3. Click 'Send test webhook'"
echo "  4. Check response - should return 200 OK"

echo -e "\n${YELLOW}Creating webhook handler file...${NC}"

# Create the webhook handler
cat > /Users/shalin/Documents/Projects/Xcode/Brrow/Brrowapp.com/api_stripe_webhook.php << 'EOF'
<?php
/**
 * Stripe Webhook Handler
 */

require_once 'api_config.php';
require_once 'api_stripe_config.php';

// Get the webhook payload and signature
$payload = @file_get_contents('php://input');
$sig_header = $_SERVER['HTTP_STRIPE_SIGNATURE'] ?? '';
$event = null;

try {
    // Verify webhook signature
    $event = \Stripe\Webhook::constructEvent(
        $payload, $sig_header, STRIPE_WEBHOOK_SECRET
    );
} catch(\UnexpectedValueException $e) {
    // Invalid payload
    http_response_code(400);
    exit();
} catch(\Stripe\Exception\SignatureVerificationException $e) {
    // Invalid signature
    http_response_code(400);
    exit();
}

// Handle the event
try {
    $db = getDB();
    
    switch ($event->type) {
        case 'payment_intent.succeeded':
            $paymentIntent = $event->data->object;
            
            // Update transaction status
            if (isset($paymentIntent->metadata->transaction_id)) {
                $stmt = $db->prepare("
                    UPDATE transactions 
                    SET payment_status = 'completed',
                        payment_intent_id = :payment_intent_id,
                        status = 'paid',
                        paid_at = NOW()
                    WHERE id = :transaction_id
                ");
                $stmt->execute([
                    'payment_intent_id' => $paymentIntent->id,
                    'transaction_id' => $paymentIntent->metadata->transaction_id
                ]);
                
                // Update payment record
                $stmt = $db->prepare("
                    UPDATE payments 
                    SET status = 'succeeded',
                        stripe_payment_intent_id = :payment_intent_id
                    WHERE transaction_id = :transaction_id
                ");
                $stmt->execute([
                    'payment_intent_id' => $paymentIntent->id,
                    'transaction_id' => $paymentIntent->metadata->transaction_id
                ]);
                
                // Send notification to owner
                $stmt = $db->prepare("
                    SELECT owner_id, renter_id, l.title 
                    FROM transactions t
                    JOIN listings l ON t.listing_id = l.id
                    WHERE t.id = :transaction_id
                ");
                $stmt->execute(['transaction_id' => $paymentIntent->metadata->transaction_id]);
                $transaction = $stmt->fetch(PDO::FETCH_ASSOC);
                
                if ($transaction) {
                    sendPushNotification(
                        $transaction['owner_id'],
                        'payment',
                        'Payment Received',
                        'Payment received for ' . $transaction['title'],
                        ['transaction_id' => $paymentIntent->metadata->transaction_id]
                    );
                }
            }
            break;
            
        case 'payment_intent.payment_failed':
            $paymentIntent = $event->data->object;
            
            if (isset($paymentIntent->metadata->transaction_id)) {
                $stmt = $db->prepare("
                    UPDATE transactions 
                    SET payment_status = 'failed'
                    WHERE id = :transaction_id
                ");
                $stmt->execute(['transaction_id' => $paymentIntent->metadata->transaction_id]);
                
                $stmt = $db->prepare("
                    UPDATE payments 
                    SET status = 'failed',
                        failure_reason = :reason
                    WHERE transaction_id = :transaction_id
                ");
                $stmt->execute([
                    'reason' => $paymentIntent->last_payment_error->message ?? 'Unknown error',
                    'transaction_id' => $paymentIntent->metadata->transaction_id
                ]);
            }
            break;
            
        case 'charge.refunded':
            $charge = $event->data->object;
            
            // Handle refund logic
            if (isset($charge->metadata->transaction_id)) {
                $stmt = $db->prepare("
                    UPDATE transactions 
                    SET payment_status = 'refunded'
                    WHERE id = :transaction_id
                ");
                $stmt->execute(['transaction_id' => $charge->metadata->transaction_id]);
            }
            break;
            
        case 'account.updated':
            $account = $event->data->object;
            
            // Update Connect account status
            $stmt = $db->prepare("
                UPDATE stripe_accounts 
                SET charges_enabled = :charges,
                    payouts_enabled = :payouts,
                    details_submitted = :details
                WHERE stripe_account_id = :account_id
            ");
            $stmt->execute([
                'charges' => $account->charges_enabled ? 1 : 0,
                'payouts' => $account->payouts_enabled ? 1 : 0,
                'details' => $account->details_submitted ? 1 : 0,
                'account_id' => $account->id
            ]);
            break;
            
        case 'customer.subscription.created':
        case 'customer.subscription.updated':
            $subscription = $event->data->object;
            
            // Update user subscription status
            $stmt = $db->prepare("
                UPDATE users 
                SET subscription_status = :status,
                    subscription_id = :sub_id,
                    subscription_end_date = FROM_UNIXTIME(:end_date)
                WHERE stripe_customer_id = :customer_id
            ");
            $stmt->execute([
                'status' => $subscription->status,
                'sub_id' => $subscription->id,
                'end_date' => $subscription->current_period_end,
                'customer_id' => $subscription->customer
            ]);
            break;
            
        case 'customer.subscription.deleted':
            $subscription = $event->data->object;
            
            $stmt = $db->prepare("
                UPDATE users 
                SET subscription_status = 'cancelled',
                    account_type = 'basic'
                WHERE stripe_customer_id = :customer_id
            ");
            $stmt->execute(['customer_id' => $subscription->customer]);
            break;
            
        default:
            // Unhandled event type
            error_log('Unhandled Stripe webhook event: ' . $event->type);
    }
    
    // Log webhook event
    $stmt = $db->prepare("
        INSERT INTO webhook_logs (
            event_id, event_type, payload, processed_at
        ) VALUES (
            :event_id, :event_type, :payload, NOW()
        )
    ");
    $stmt->execute([
        'event_id' => $event->id,
        'event_type' => $event->type,
        'payload' => $payload
    ]);
    
    http_response_code(200);
    echo json_encode(['success' => true]);
    
} catch (Exception $e) {
    error_log('Webhook error: ' . $e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'Webhook handler error']);
}
?>
EOF

echo -e "${GREEN}✓${NC} Webhook handler created"

echo -e "\n${GREEN}================================================${NC}"
echo -e "${GREEN}    STRIPE WEBHOOK SETUP COMPLETE${NC}"
echo -e "${GREEN}================================================${NC}"

echo -e "\n${YELLOW}Manual Steps Required:${NC}"
echo "1. ⚠️  Add webhook endpoint in Stripe Dashboard"
echo "2. ⚠️  Copy the webhook signing secret"
echo "3. ⚠️  Update the secret in configuration"
echo "4. ⚠️  Test the webhook endpoint"

echo -e "\n${BLUE}Webhook Endpoint URL:${NC}"
echo -e "${GREEN}https://brrowapp.com/brrow/api_stripe_webhook.php${NC}"

echo -e "\n${YELLOW}Testing Webhook:${NC}"
echo "Use Stripe CLI for local testing:"
echo "  stripe listen --forward-to https://brrowapp.com/brrow/api_stripe_webhook.php"
echo "  stripe trigger payment_intent.succeeded"