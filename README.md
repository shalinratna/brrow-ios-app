# Brrow Admin Panel - Production Deployment

## 🚀 Live URL
**Admin Panel**: https://admin.brrowapp.com

## 📁 Project Structure
```
brrowapp-deployment/
├── admin/              # Admin panel (Next.js production build)
├── api/                # Backend API (Node.js/Express)
├── docs/               # Documentation
├── assets/             # Static assets
└── brrow-admin/        # Source code for admin panel
```

## ✅ Features Ready for Production
- **User Management**: View, edit, verify, and delete users (110+ users loaded)
- **Bulk Operations**: Mass delete, verify, and manage users
- **Garage Sales Management**: Full CRUD operations
- **Marketplace Management**: Listings oversight
- **Messages Management**: Conversation monitoring
- **Real-time Analytics**: Live dashboard with server stats
- **Authentication**: JWT-based admin login system
- **Database Integration**: Railway PostgreSQL

## 🔧 Deployment Setup

### Prerequisites
- Node.js 18+
- Railway PostgreSQL database
- Domain/subdomain configured for admin.brrowapp.com

### Environment Variables
```bash
DATABASE_URL="postgresql://postgres:kciFfaaVBLcfEAlHomvyNFnbMjIxGdOE@yamanote.proxy.rlwy.net:10740/railway"
JWT_SECRET="brrow-secret-key-2024"
NEXT_PUBLIC_API_URL="https://brrow-backend-nodejs-production.up.railway.app"
```

### Quick Start
1. **Clone the repository**
   ```bash
   git clone https://github.com/shalinratna/brrow-ios-app.git
   cd brrowapp-deployment
   ```

2. **Install dependencies**
   ```bash
   cd brrow-admin && npm install
   ```

3. **Build for production**
   ```bash
   npm run build
   ```

4. **Start production server**
   ```bash
   npm start
   ```

## 🔐 Admin Login
- **URL**: https://admin.brrowapp.com/login
- **Email**: admin@shaiitech.com
- **Password**: admin123456

## 🚀 Auto-Deployment Script
The repository includes GitHub Actions for automatic deployment when pushing to the `admin-deployment` branch.

## 📊 Database Schema
- **Users**: 110+ active users with real data
- **Listings**: Marketplace items
- **Garage Sales**: Event management
- **Messages**: Communication logs
- **Notifications**: System alerts

## 🔧 Production Configuration
- **Build Tool**: Next.js 15.5.3
- **Database**: Railway PostgreSQL
- **Authentication**: JWT with 7-day expiry
- **API Base**: Railway-hosted backend
- **Frontend**: Static optimized build

## 🛠️ Maintenance
To update the admin panel:
1. Make changes to `brrow-admin/` directory
2. Test locally with `npm run dev`
3. Build with `npm run build`
4. Commit and push to `admin-deployment` branch
5. Auto-deployment will handle the rest

## 📞 Support
For any issues or updates, contact the development team.

---
**Last Updated**: $(date)
**Version**: 1.0.0
**Status**: ✅ Production Ready