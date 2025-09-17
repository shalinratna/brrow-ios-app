# CLAUDE - Brrow Platform Development Assistant

## 🤖 About Me
- **Name**: Claude
- **Role**: Lead Development Assistant for Brrow Platform
- **Owner**: Shalin
- **Mission**: Build a complete peer-to-peer rental marketplace platform

## 🎯 Current Project Status
**Platform**: Brrow - Peer-to-peer rental and selling marketplace
**Tech Stack**: 
- iOS (Swift/SwiftUI)
- Backend (Node.js/Express)
- Database (PostgreSQL/Railway)
- Deployment (Railway)

## ✅ Completed Features
- [x] User Authentication System
- [x] Basic Listing Creation & Upload
- [x] Listing Details View (Owner/Buyer differentiation)
- [x] Image Gallery with Full-Screen Viewer
- [x] Backend API Deployment
- [x] Database Structure
- [x] Brrow Protection Display ($120 coverage, 10% cost)

## 🚀 Active Development (In Order)
1. **Search & Discovery** ← CURRENT
2. Messaging System
3. Payment Integration
4. Booking & Calendar
5. Reviews & Ratings
6. Admin Panel
7. Notifications
8. User Profiles
9. Analytics Dashboard
10. Offers & Negotiations

## 📝 Development Rules
- Complete each feature fully before moving to the next
- Ask Shalin for clarification on big decisions
- Test everything thoroughly
- Keep UI simple, modern, and Facebook Marketplace-inspired
- Ensure all listing data is accurate
- Full permissions to edit and run necessary commands

## 🔧 Common Commands
```bash
# Backend
cd /Users/shalin/Documents/Projects/Xcode/Brrow/brrow-backend
npm start
DATABASE_URL="postgresql://postgres:kciFfaaVBLcfEAlHomvyNFnbMjIxGdOE@yamanote.proxy.rlwy.net:10740/railway" JWT_SECRET=brrow-secret-key-2024 PORT=3002 node prisma-server.js

# iOS Build
xcodebuild -project Brrow.xcodeproj -scheme Brrow -destination 'platform=iOS Simulator,name=iPhone 15'

# Git
git add .
git commit -m "Feature: [description]"
git push
```

## 🗂️ Project Structure
```
/Brrow
  /Views - SwiftUI Views
  /ViewModels - View Models
  /Models - Data Models
  /Services - API & Services
  /brrow-backend - Node.js Backend
    /routes - API Routes
    /prisma - Database Schema
    server.js - Main Server
```

## 📊 Database Connection
- **URL**: postgresql://postgres:kciFfaaVBLcfEAlHomvyNFnbMjIxGdOE@yamanote.proxy.rlwy.net:10740/railway
- **Platform**: Railway (NOT Supabase)
- **JWT Secret**: brrow-secret-key-2024
- **API Base**: https://brrow-backend-nodejs-production.up.railway.app

## 👤 Admin Access
- Admin panel to be built for complete platform oversight
- Developer tools for monitoring all app activities
- Full CRUD operations on all entities

---
*Last Updated: [Auto-updates with each session]*