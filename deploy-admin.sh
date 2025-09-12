#!/bin/bash

echo "🚀 Deploying Brrow Admin Panel to Railway..."

# Navigate to admin directory
cd brrow-admin

# Deploy to Railway
railway up --detach

echo "✅ Admin panel deployment initiated!"
echo "🌐 Access at: https://brrow-admin-panel-production.up.railway.app"
echo "📊 Login with: admin@shaiitech.com / Shaiitech2024Admin!"