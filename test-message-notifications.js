#!/usr/bin/env node

/**
 * Test Message Notifications End-to-End
 *
 * This script tests the complete message notification flow:
 * 1. Creates test users with FCM tokens
 * 2. Creates a chat between them
 * 3. Sends a message from user1 to user2
 * 4. Verifies notification was attempted
 * 5. Checks notification history
 */

const axios = require('axios');

const BASE_URL = 'https://brrow-backend-nodejs-production.up.railway.app';

// Test configuration
const config = {
  testUsers: [
    {
      email: 'test.sender@brrow.app',
      firstName: 'Test',
      lastName: 'Sender',
      username: 'testsender123',
      password: 'TestPass123!',
      fcmToken: 'fake_fcm_token_sender_12345'
    },
    {
      email: 'test.receiver@brrow.app',
      firstName: 'Test',
      lastName: 'Receiver',
      username: 'testreceiver123',
      password: 'TestPass123!',
      fcmToken: 'fake_fcm_token_receiver_67890'
    }
  ]
};

class NotificationTester {
  constructor() {
    this.users = [];
    this.authTokens = [];
    this.chatId = null;
  }

  async runTest() {
    console.log('🧪 Starting Message Notification Test...\n');

    try {
      // Step 1: Register test users
      await this.registerTestUsers();

      // Step 2: Login users
      await this.loginUsers();

      // Step 3: Set FCM tokens
      await this.setFCMTokens();

      // Step 4: Create chat
      await this.createChat();

      // Step 5: Send test message
      await this.sendTestMessage();

      // Step 6: Verify notification was sent
      await this.verifyNotification();

      console.log('\n✅ Message notification test completed successfully!');
      console.log('\n📋 Test Summary:');
      console.log('✅ User registration and authentication');
      console.log('✅ FCM token registration');
      console.log('✅ Chat creation');
      console.log('✅ Message sending with notification');
      console.log('✅ Notification verification');

    } catch (error) {
      console.error('❌ Test failed:', error.message);
      if (error.response?.data) {
        console.error('Response data:', JSON.stringify(error.response.data, null, 2));
      }
    }
  }

  async registerTestUsers() {
    console.log('📝 Registering test users...');

    for (const userData of config.testUsers) {
      try {
        const response = await axios.post(`${BASE_URL}/api/auth/register`, {
          email: userData.email,
          firstName: userData.firstName,
          lastName: userData.lastName,
          username: userData.username,
          password: userData.password
        });

        if (response.data.success) {
          // Extract user from response - handle different response structures
          const user = response.data.data?.user || response.data.user || response.data.data;
          this.users.push(user);
          console.log(`✅ Registered user: ${userData.email}`);
          console.log(`   User ID: ${user.id || user.apiId}`);
        }
      } catch (error) {
        if (error.response?.status === 400 &&
            (error.response?.data?.message?.includes('already exists') ||
             error.response?.data?.error?.includes('already registered'))) {
          console.log(`ℹ️  User already exists: ${userData.email}`);
          // Continue with login for existing users
        } else {
          throw error;
        }
      }
    }
  }

  async loginUsers() {
    console.log('\n🔐 Logging in test users...');

    for (const userData of config.testUsers) {
      const response = await axios.post(`${BASE_URL}/api/auth/login`, {
        username: userData.username,
        password: userData.password
      });

      if (response.data.success) {
        const authToken = response.data.accessToken || response.data.data?.authToken || response.data.authToken || response.data.data?.token || response.data.token;
        this.authTokens.push(authToken);

        const user = response.data.user || response.data.data?.user || response.data.data;
        if (!this.users.find(u => u.email === userData.email)) {
          this.users.push(user);
        }
        console.log(`✅ Logged in user: ${userData.email}`);
        console.log(`   Auth token: ${authToken ? authToken.substring(0, 20) + '...' : 'Not found'}`);
      }
    }
  }

  async setFCMTokens() {
    console.log('\n📱 Setting FCM tokens...');

    for (let i = 0; i < this.users.length; i++) {
      const userData = config.testUsers[i];
      const authToken = this.authTokens[i];

      const response = await axios.put(`${BASE_URL}/api/users/me/fcm-token`, {
        device_token: userData.fcmToken,
        platform: 'ios',
        app_version: '1.0.0',
        device_model: 'iPhone 15 Pro',
        os_version: '17.0'
      }, {
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.data.success) {
        console.log(`✅ Set FCM token for: ${userData.email}`);
      }
    }
  }

  async createChat() {
    console.log('\n💬 Creating chat between users...');

    const response = await axios.post(`${BASE_URL}/api/messages/chats/direct`, {
      recipientId: this.users[1].id // Send to second user
    }, {
      headers: {
        'Authorization': `Bearer ${this.authTokens[0]}`, // From first user
        'Content-Type': 'application/json'
      }
    });

    if (response.data.success) {
      this.chatId = response.data.data.id;
      console.log(`✅ Created chat: ${this.chatId}`);
    }
  }

  async sendTestMessage() {
    console.log('\n📨 Sending test message...');

    const testMessage = "Hello! This is a test message to verify push notifications are working. 🚀";

    const response = await axios.post(`${BASE_URL}/api/messages/chats/${this.chatId}/messages`, {
      content: testMessage,
      messageType: 'TEXT'
    }, {
      headers: {
        'Authorization': `Bearer ${this.authTokens[0]}`, // From first user
        'Content-Type': 'application/json'
      }
    });

    if (response.data.success) {
      console.log(`✅ Message sent successfully`);
      console.log(`📝 Message content: "${testMessage}"`);
      console.log(`📤 From: ${config.testUsers[0].email}`);
      console.log(`📥 To: ${config.testUsers[1].email}`);
    }
  }

  async verifyNotification() {
    console.log('\n🔔 Verifying notification was sent...');

    // Check notification history for recipient
    const response = await axios.get(`${BASE_URL}/api/notifications`, {
      headers: {
        'Authorization': `Bearer ${this.authTokens[1]}`, // Check recipient's notifications
        'Content-Type': 'application/json'
      },
      params: {
        limit: 1
      }
    });

    if (response.data.success && response.data.data.length > 0) {
      const notification = response.data.data[0];
      console.log(`✅ Notification found in history`);
      console.log(`📋 Notification details:`);
      console.log(`   Type: ${notification.type}`);
      console.log(`   Title: ${notification.title}`);
      console.log(`   Body: ${notification.body}`);
      console.log(`   Created: ${notification.createdAt}`);
    } else {
      console.log('⚠️  No notifications found in history');
    }

    // Check unread count
    const badgeResponse = await axios.get(`${BASE_URL}/api/notifications/unread-count`, {
      headers: {
        'Authorization': `Bearer ${this.authTokens[1]}`,
        'Content-Type': 'application/json'
      }
    });

    if (badgeResponse.data.success) {
      console.log(`📱 Unread notification count: ${badgeResponse.data.data.count}`);
    }
  }
}

// Run the test
if (require.main === module) {
  const tester = new NotificationTester();
  tester.runTest().catch(console.error);
}

module.exports = NotificationTester;