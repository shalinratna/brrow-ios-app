# Brrow Development Log
## Lead Developer Session Notes

### Project Status (Current)
- **Date Started**: January 2025
- **Platform**: iOS marketplace app competing with Facebook Marketplace
- **Architecture**: iOS Swift frontend + Node.js/Express backend + PostgreSQL on Railway
- **Domain**: brrowapp.com (hosted on Awardspace)

### Key Decisions Made
1. Building for STABILITY over SPEED - no rushing
2. Full production-ready implementation
3. Using Railway for backend, Awardspace for domain
4. PostgreSQL as primary database
5. Email verification required for accounts

### User Account System Requirements
- Full CRUD operations
- Email verification via noreply@brrowapp.com
- Email templates stored on brrowapp.com
- Match existing PHP implementation patterns
- Secure, stable, production-ready

### Questions for Product Owner
1. **Email Service**: Should we use SendGrid, AWS SES, or SMTP direct from Railway?
2. **User Deletion**: Soft delete (mark inactive) or hard delete (remove data)?
3. **Username Policy**: Allow changes? How often? Must be unique?
4. **Account Recovery**: Email-based? Security questions? 2FA?
5. **Profile Fields**: Required vs optional fields?

### Technical Architecture Notes
- Frontend: 90% complete (iOS Swift)
- Backend: 20% complete (Node.js/Express)
- Database: Schema defined with Prisma
- Auth: JWT tokens (access + refresh)

### Next Implementation Phase
- User account CRUD system
- Email verification flow
- Profile management endpoints
- Account security features

Answers:
- Emails will be sent from brrowapp.com from SMTP from Awardspace.
- When a user deleted their account it will Soft Delete. All Brrow data on the platform will be soft deleted. Unless it is useless then we can hybrid that data.
- Users can change their username once every 90 days. But if they change it, they still get rights to change it back to that name within that 90 day window if they decide to change. After, their username is up for grabs by another user. So even if a user changed their username to another one and a another user wants it but the original user is still within 90 days of changing it, then the other user would not be able to get that desired username. Only text and numbers are allowed. No special characters. 
- Okay so there are two types of verification on the platform. Email verified and Account verified. So a user must verify their email address prior to posting anything. When a user signs up they can do anything, they just can not post anything to the platform such as listings, seeks, or garage sales. But once email verified they have full access. Account verification is done via ID via ID.me and once done, accounts will receive a green check mark next to their name everytime on the platform. 
- Profile fields just match whatever the existing UI is. That is all correct for profile fields.   2. Profile Fields - Which should be required at signup vs. optional later?
    - Required: username, email, password, birthdate (I see from PHP)
    - Optional: phone, bio, location, profile picture? 
    - First and last name are required but are not public and will not be seen by others on platform.
    - When a user deleted account their listings get hidden, and backend soft deleeted. 
    - When user deletes their account the chats stay for the other person it just says deleted user or user not found or Brrow user like Instagram.
-
    
Information:
- User's will have an API id that will be used for everything. API id acts as primary key. Foreign key for other tables to use of course.

## Implementation Progress (Current Session)

### ✅ Completed Today:
1. **User Registration Enhancement**
   - Added email verification token generation on signup
   - Tokens expire in 24 hours
   - User created with isVerified: false

2. **Username Change System**
   - Implemented 90-day policy
   - Added UsernameHistory model
   - Previous username reserved for 90 days
   - User can revert to old username within window
   - Alphanumeric only validation

3. **Email Verification Middleware**
   - Created requireVerifiedEmail middleware
   - Applied to listing creation endpoint
   - Users can browse without verification
   - Cannot post listings/seeks/garage sales until verified

4. **Database Schema Updates**
   - EmailVerificationToken model
   - PasswordResetToken model
   - UsernameHistory model
   - Soft delete fields (deletedAt, emailVerifiedAt)

### ✅ Just Completed:
1. **SMTP Configuration**
   - Configured mboxhosting.com SMTP
   - Port 587 with STARTTLS
   - Email service ready to send

2. **API ID Format Fixed**
   - Now exactly 14 characters
   - Format: `usr_XXXXXXXXXX`
   - Uses timestamp + random for uniqueness

3. **Soft Delete Endpoint**
   - DELETE /api/users/me
   - Requires password + "DELETE" confirmation
   - Anonymizes user data
   - Hides listings/seeks/garage sales
   - Messages preserved showing "Deleted User"

### 🔧 Next Steps:
1. Add password reset endpoints
2. Integrate ID.me for green checkmark verification
3. Add verification boost popup for listings
4. Implement verified-only marketplace filter
5. Test email sending with real SMTP credentials

### Notes:
- API ID format: `usr_{timestamp}_{random}`
- Email verification required for posting only
- First/last names stored but not public
- Deleted users show as "Deleted User" in chats

