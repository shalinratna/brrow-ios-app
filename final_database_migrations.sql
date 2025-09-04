-- ================================================
-- BRROW APP - FINAL DATABASE MIGRATIONS
-- ================================================

-- 1. RENTAL TRANSACTIONS
CREATE TABLE IF NOT EXISTS rental_transactions (
    id SERIAL PRIMARY KEY,
    transaction_id VARCHAR(50) UNIQUE NOT NULL,
    listing_id INTEGER NOT NULL,
    renter_id INTEGER NOT NULL,
    owner_id INTEGER NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    rental_fee DECIMAL(10,2) NOT NULL,
    security_deposit DECIMAL(10,2),
    platform_fee DECIMAL(10,2),
    status VARCHAR(20) DEFAULT 'pending',
    delivery_method VARCHAR(20),
    pickup_location TEXT,
    special_instructions TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (listing_id) REFERENCES listings(id),
    FOREIGN KEY (renter_id) REFERENCES users(id),
    FOREIGN KEY (owner_id) REFERENCES users(id)
);

-- 2. PAYMENT RECORDS
CREATE TABLE IF NOT EXISTS payments (
    id SERIAL PRIMARY KEY,
    payment_id VARCHAR(100) UNIQUE NOT NULL,
    transaction_id VARCHAR(50) NOT NULL,
    stripe_payment_intent_id VARCHAR(255),
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    status VARCHAR(20) DEFAULT 'pending',
    payment_method VARCHAR(50),
    payout_status VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (transaction_id) REFERENCES rental_transactions(transaction_id)
);

-- 3. STRIPE ACCOUNTS
CREATE TABLE IF NOT EXISTS stripe_accounts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE NOT NULL,
    stripe_account_id VARCHAR(255) UNIQUE,
    onboarding_complete BOOLEAN DEFAULT FALSE,
    charges_enabled BOOLEAN DEFAULT FALSE,
    payouts_enabled BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- 4. DEVICE TOKENS FOR PUSH NOTIFICATIONS
CREATE TABLE IF NOT EXISTS device_tokens (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    device_token VARCHAR(255) NOT NULL,
    platform VARCHAR(10) DEFAULT 'ios',
    app_version VARCHAR(20),
    device_model VARCHAR(50),
    os_version VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, device_token),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- 5. NOTIFICATIONS
CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    data JSONB,
    image_url TEXT,
    action_url TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- 6. NOTIFICATION PREFERENCES
CREATE TABLE IF NOT EXISTS notification_preferences (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE NOT NULL,
    rental_requests BOOLEAN DEFAULT TRUE,
    rental_updates BOOLEAN DEFAULT TRUE,
    messages BOOLEAN DEFAULT TRUE,
    marketing BOOLEAN DEFAULT TRUE,
    push_enabled BOOLEAN DEFAULT TRUE,
    email_enabled BOOLEAN DEFAULT TRUE,
    quiet_hours_enabled BOOLEAN DEFAULT FALSE,
    quiet_hours_start TIME DEFAULT '22:00',
    quiet_hours_end TIME DEFAULT '08:00',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- 7. CONVERSATIONS
CREATE TABLE IF NOT EXISTS conversations (
    id SERIAL PRIMARY KEY,
    listing_id INTEGER,
    participant1_id INTEGER NOT NULL,
    participant2_id INTEGER NOT NULL,
    last_message_at TIMESTAMP,
    last_message_text TEXT,
    unread_count_p1 INTEGER DEFAULT 0,
    unread_count_p2 INTEGER DEFAULT 0,
    is_archived BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (listing_id) REFERENCES listings(id),
    FOREIGN KEY (participant1_id) REFERENCES users(id),
    FOREIGN KEY (participant2_id) REFERENCES users(id)
);

-- 8. MESSAGES
CREATE TABLE IF NOT EXISTS messages (
    id SERIAL PRIMARY KEY,
    conversation_id INTEGER NOT NULL,
    sender_id INTEGER NOT NULL,
    message_text TEXT NOT NULL,
    message_type VARCHAR(20) DEFAULT 'text',
    attachment_url TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (conversation_id) REFERENCES conversations(id),
    FOREIGN KEY (sender_id) REFERENCES users(id)
);

-- 9. REVIEWS
CREATE TABLE IF NOT EXISTS reviews (
    id SERIAL PRIMARY KEY,
    transaction_id VARCHAR(50),
    reviewer_id INTEGER NOT NULL,
    reviewed_user_id INTEGER NOT NULL,
    listing_id INTEGER,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    title VARCHAR(255),
    comment TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    helpful_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (transaction_id) REFERENCES rental_transactions(transaction_id),
    FOREIGN KEY (reviewer_id) REFERENCES users(id),
    FOREIGN KEY (reviewed_user_id) REFERENCES users(id),
    FOREIGN KEY (listing_id) REFERENCES listings(id)
);

-- 10. USER LOCATIONS
CREATE TABLE IF NOT EXISTS user_locations (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(50),
    country VARCHAR(50),
    postal_code VARCHAR(20),
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_rental_transactions_status ON rental_transactions(status);
CREATE INDEX IF NOT EXISTS idx_rental_transactions_dates ON rental_transactions(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_reviews_listing ON reviews(listing_id);
CREATE INDEX IF NOT EXISTS idx_user_locations_coords ON user_locations(latitude, longitude);

-- Add missing columns to existing tables if they don't exist
DO $$ 
BEGIN
    -- Add Stripe fields to users table if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='users' AND column_name='stripe_customer_id') THEN
        ALTER TABLE users ADD COLUMN stripe_customer_id VARCHAR(255) UNIQUE;
    END IF;
    
    -- Add location fields to listings if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='listings' AND column_name='latitude') THEN
        ALTER TABLE listings ADD COLUMN latitude DECIMAL(10, 8);
        ALTER TABLE listings ADD COLUMN longitude DECIMAL(11, 8);
    END IF;
    
    -- Add push notification fields to users if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='users' AND column_name='push_enabled') THEN
        ALTER TABLE users ADD COLUMN push_enabled BOOLEAN DEFAULT TRUE;
    END IF;
END $$;

-- Grant permissions (adjust based on your database user)
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO your_db_user;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO your_db_user;

COMMIT;
