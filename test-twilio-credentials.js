#!/usr/bin/env node

// Test Twilio credential validation logic
console.log('🔍 Testing Twilio credential validation...');

function checkTwilioCredentials() {
  console.log('\n📊 Environment variables:');
  console.log('TWILIO_ACCOUNT_SID:', process.env.TWILIO_ACCOUNT_SID || 'undefined');
  console.log('TWILIO_AUTH_TOKEN:', process.env.TWILIO_AUTH_TOKEN || 'undefined');
  console.log('TWILIO_VERIFY_SERVICE_SID:', process.env.TWILIO_VERIFY_SERVICE_SID || 'undefined');

  // Our improved validation logic
  const isConfigured = process.env.TWILIO_ACCOUNT_SID &&
                      process.env.TWILIO_AUTH_TOKEN &&
                      process.env.TWILIO_VERIFY_SERVICE_SID &&
                      process.env.TWILIO_ACCOUNT_SID.trim() !== '' &&
                      process.env.TWILIO_AUTH_TOKEN.trim() !== '' &&
                      process.env.TWILIO_VERIFY_SERVICE_SID.trim() !== '';

  console.log('\n✅ Credential check result:', isConfigured ? 'CONFIGURED' : 'NOT CONFIGURED');

  if (!isConfigured) {
    console.log('📱 SMS verification service not configured');
    console.log('🔧 Missing credentials:');
    if (!process.env.TWILIO_ACCOUNT_SID || process.env.TWILIO_ACCOUNT_SID.trim() === '') {
      console.log('   • TWILIO_ACCOUNT_SID');
    }
    if (!process.env.TWILIO_AUTH_TOKEN || process.env.TWILIO_AUTH_TOKEN.trim() === '') {
      console.log('   • TWILIO_AUTH_TOKEN');
    }
    if (!process.env.TWILIO_VERIFY_SERVICE_SID || process.env.TWILIO_VERIFY_SERVICE_SID.trim() === '') {
      console.log('   • TWILIO_VERIFY_SERVICE_SID');
    }
  }

  return isConfigured;
}

checkTwilioCredentials();