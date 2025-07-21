# 🚀 Ebeautything MVP Development Guide - Complete Step-by-Step Instructions

## 📋 **Phase 1: Project Setup & Infrastructure (Week 1)**

### **Day 1: Initial Project Setup**

#### **1.1 Create Development Environment**
1. **Set up development machine:**
   - Install Flutter SDK (latest stable version)
   - Install Android Studio with Android SDK
   - Install Xcode (for iOS development - Mac only)
   - Install VS Code with Flutter/Dart extensions
   - Install Node.js (LTS version) and npm
   - Install Git for version control

2. **Create project repositories:**
   - Create GitHub organization "ebeautything"
   - Create three repositories:
     - `ebeautything-flutter` (Flutter mobile app)
     - `ebeautything-admin` (React web admin)
     - `ebeautything-docs` (Documentation and assets)
   - Set up proper README files for each repo
   - Configure branch protection rules (main branch)
   - Add .gitignore files for each project type

#### **1.2 Create Supabase Project**
1. **Create Supabase account and project:**
   - Go to supabase.com and sign up
   - Create organization "Ebeautything"
   - Create new project: "ebeautything-prod"
   - Generate strong database password
   - Select region: Asia Northeast (Seoul)
   - Wait for project provisioning (5-10 minutes)

2. **Save important credentials securely:**
   - Project URL
   - Anon public key
   - Service role key (keep secret)
   - Database password
   - JWT secret
   - Store in secure password manager or environment variables

### **Day 2: Database Setup**

#### **2.1 Execute Database Schema**
1. **Open Supabase SQL Editor:**
   - Navigate to SQL Editor in Supabase dashboard
   - Create new query tab

2. **Execute schema in sections (to avoid timeouts):**
   - **Section 1:** Extensions and Enums
     ```sql
     -- Copy and execute enum definitions
     CREATE TYPE user_gender AS ENUM...
     CREATE TYPE user_status AS ENUM...
     -- Continue with all enum definitions
     ```
   - **Section 2:** Core User and Shop Tables
     ```sql
     -- Execute users, user_settings, shops, shop_images tables
     ```
   - **Section 3:** Service and Reservation Tables
     ```sql
     -- Execute shop_services, reservations, payments tables
     ```
   - **Section 4:** Points and Notification Tables
     ```sql
     -- Execute point_transactions, notifications, user_favorites
     ```
   - **Section 5:** Indexes and Performance
     ```sql
     -- Execute all CREATE INDEX statements
     ```
   - **Section 6:** RLS Policies
     ```sql
     -- Execute all Row Level Security policies
     ```
   - **Section 7:** Functions and Triggers
     ```sql
     -- Execute all functions and triggers
     ```
   - **Section 8:** Admin Views
     ```sql
     -- Execute admin views for web dashboard
     ```

3. **Verify database setup:**
   - Check Table Editor to confirm all 15 tables exist
   - Verify all enums in Database > Types
   - Test admin views by running SELECT queries
   - Confirm RLS is enabled on all tables

#### **2.2 Configure Storage Buckets**
1. **Create storage buckets:**
   - Go to Storage in Supabase dashboard
   - Create bucket: `profile-images` 
     - Set to public
     - Max file size: 5MB
     - Allowed types: image/jpeg, image/png
   - Create bucket: `shop-images`
     - Set to public
     - Max file size: 10MB
     - Allowed types: image/jpeg, image/png
   - Create bucket: `service-images`
     - Set to public
     - Max file size: 10MB
     - Allowed types: image/jpeg, image/png
   - Create bucket: `business-documents`
     - Set to private
     - Max file size: 20MB
     - Allowed types: image/jpeg, image/png, application/pdf

2. **Configure storage policies:**
   - Set up RLS policies for each bucket
   - Allow users to upload their own profile images
   - Allow shop owners to upload shop/service images
   - Restrict business documents to admin access

#### **2.3 Configure Authentication Providers**
1. **Set up Google OAuth:**
   - Go to Google Cloud Console
   - Create new project or use existing
   - Enable Google+ API
   - Create OAuth 2.0 credentials
   - Add authorized origins (Supabase callback URL)
   - Copy Client ID and Secret to Supabase Auth settings

2. **Set up Apple Sign-In:**
   - Go to Apple Developer Console
   - Create App ID with Sign in with Apple capability
   - Create Service ID for web authentication
   - Generate private key for authentication
   - Configure Supabase with Apple credentials

3. **Set up Kakao OAuth:**
   - Register at Kakao Developers
   - Create new application
   - Get REST API key and JavaScript key
   - Configure redirect URIs
   - Add credentials to Supabase Auth settings

4. **Configure Supabase Auth settings:**
   - Set site URL to your production domain
   - Add redirect URLs for mobile app (custom scheme)
   - Enable email confirmations (optional for MVP)
   - Set password policy requirements

### **Day 3: External Service Setup**

#### **3.1 Set Up PASS인증 (Korean Identity Verification)**
1. **Choose and register with PASS인증 provider:**
   - Research providers: NICE Information & Communication, Korea Credit Bureau (KCB)
   - Complete business registration process
   - Submit required documents (business license, etc.)
   - Wait for approval (typically 3-5 business days)

2. **Get development credentials:**
   - Receive test environment API endpoints
   - Get API keys and certificates
   - Download SDK documentation
   - Set up test environment access

3. **Review integration requirements:**
   - Study API documentation thoroughly
   - Understand verification flow
   - Note required user data fields
   - Plan error handling scenarios

#### **3.2 Set Up Toss Payments**
1. **Register Toss Payments account:**
   - Go to Toss Payments business portal
   - Complete business verification process
   - Submit required documents
   - Wait for account approval

2. **Get sandbox credentials:**
   - Access test environment
   - Get test API keys and secrets
   - Review integration documentation
   - Download test card numbers

3. **Configure payment settings:**
   - Set up supported payment methods (card, KakaoPay)
   - Configure webhook endpoints (placeholder URLs for now)
   - Review settlement and fee structure
   - Understand refund process

#### **3.3 Set Up Firebase for Push Notifications**
1. **Create Firebase project:**
   - Go to Firebase Console
   - Create new project "ebeautything"
   - Enable Google Analytics (optional)

2. **Configure for Android:**
   - Add Android app to Firebase project
   - Package name: `com.ebeautything.app`
   - Download `google-services.json`
   - Note Server Key for backend

3. **Configure for iOS:**
   - Add iOS app to Firebase project
   - Bundle ID: `com.ebeautything.app`
   - Download `GoogleService-Info.plist`
   - Upload APNs certificate

### **Day 4-5: Development Environment Finalization**

#### **4.1 Create Flutter Project Structure**
1. **Initialize Flutter project:**
   - Run `flutter create ebeautything_app`
   - Set up folder structure according to development guide
   - Configure `pubspec.yaml` with required dependencies
   - Set up environment configuration files

2. **Configure project settings:**
   - Update app name and description
   - Set up app icons and splash screens
   - Configure Android manifest permissions
   - Set up iOS Info.plist permissions

#### **4.2 Create React Admin Project**
1. **Initialize React project:**
   - Run `npx create-react-app ebeautything-admin --template typescript`
   - Install required dependencies (Material-UI, Supabase client)
   - Set up folder structure
   - Configure environment variables

2. **Set up basic authentication:**
   - Create login component
   - Set up Supabase client configuration
   - Implement basic auth flow
   - Create protected route wrapper

## 📱 **Phase 2: Flutter Mobile App Development (Weeks 2-6)**

### **Week 2: Core App Structure & Authentication**

#### **Day 1: Project Architecture Setup**
1. **Set up BLoC architecture:**
   - Create core folder structure
   - Set up dependency injection with Provider
   - Create base BLoC classes
   - Set up repository pattern

2. **Configure Supabase client:**
   - Add Supabase Flutter dependency
   - Create Supabase service class
   - Set up environment configurations
   - Test database connection

#### **Day 2-3: Authentication Implementation**
1. **Implement social authentication:**
   - Create auth repository
   - Implement Google Sign-In flow
   - Implement Apple Sign-In flow
   - Implement Kakao Sign-In flow
   - Create auth BLoC for state management

2. **Create authentication screens:**
   - Design welcome/login screen
   - Implement social login buttons
   - Add loading states and error handling
   - Create user session management

#### **Day 4-5: PASS인증 Integration**
1. **Integrate PASS인증 SDK:**
   - Add PASS인증 dependencies
   - Configure native Android/iOS settings
   - Create phone verification service
   - Implement verification flow

2. **Create phone verification screens:**
   - Phone number input screen
   - PASS인증 verification interface
   - Success/failure handling
   - Link verification to user profile

### **Week 3: User Profile & Core Navigation**

#### **Day 1-2: User Profile Creation**
1. **Create profile setup flow:**
   - Name and basic info input
   - Profile picture upload
   - Birth date and gender selection
   - Terms and privacy acceptance
   - Referral code entry (optional)

2. **Implement profile management:**
   - Create user profile BLoC
   - Implement image upload to Supabase Storage
   - Save user data to users table
   - Handle form validation

#### **Day 3-4: Core Navigation Structure**
1. **Set up bottom navigation:**
   - Create main navigation wrapper
   - Implement 4 main tabs: Home, Search, Reservations, Profile
   - Set up navigation state management
   - Add badge system for notifications

2. **Create basic screens:**
   - Home screen placeholder
   - Search screen placeholder
   - Reservations screen placeholder
   - Profile screen with user info

#### **Day 5: Location Services**
1. **Implement location functionality:**
   - Add geolocator dependency
   - Request location permissions
   - Get current user location
   - Handle location errors and fallbacks

### **Week 4: Shop Discovery & Search**

#### **Day 1-2: Shop Discovery Implementation**
1. **Create shop discovery logic:**
   - Implement shop repository
   - Create shop BLoC for state management
   - Fetch shops based on location
   - Implement shop exposure algorithm (prioritize partnered shops)

2. **Design shop listing UI:**
   - Create shop card component
   - Implement infinite scrolling with pagination (30 shops per load)
   - Add pull-to-refresh functionality
   - Show distance, rating, partnership status

#### **Day 3-4: Search & Filtering**
1. **Implement search functionality:**
   - Create search input with debouncing
   - Implement text search by shop name
   - Store and display recent searches
   - Add search history management

2. **Add filtering system:**
   - Filter by service categories (nail, eyelash, waxing, eyebrow_tattoo)
   - Sort by distance, partnership status
   - Create filter UI components
   - Implement filter state management

#### **Day 5: Shop Detail Screen**
1. **Create shop detail screen:**
   - Display shop information (name, address, phone, hours)
   - Show shop images gallery
   - Display partnership badge
   - List available services with pricing
   - Add call and favorite functionality

### **Week 5: Reservation System**

#### **Day 1-2: Service Selection**
1. **Create service selection flow:**
   - Display shop services from shop_services table
   - Implement service selection with quantity
   - Calculate total pricing
   - Show service details and duration

#### **Day 3-4: Booking Flow**
1. **Implement reservation creation:**
   - Create calendar widget for date selection
   - Add time slot selection
   - Implement availability checking
   - Create reservation summary screen

2. **Add reservation management:**
   - Create reservation BLoC
   - Save reservation to database
   - Handle reservation status updates
   - Implement cancellation flow

#### **Day 5: Payment Integration**
1. **Integrate Toss Payments:**
   - Add Toss Payments SDK
   - Implement payment flow
   - Handle deposit payments
   - Create payment success/failure screens
   - Save payment records to payments table

### **Week 6: Points System & User Features**

#### **Day 1-2: Points System**
1. **Implement points functionality:**
   - Create points BLoC
   - Display user point balance
   - Show point transaction history
   - Implement point usage during payment

2. **Add referral system:**
   - Display user's referral code
   - Implement referral code sharing
   - Track referral progress
   - Show influencer status progress

#### **Day 3-4: User Profile & Settings**
1. **Complete profile management:**
   - Edit profile information
   - Change profile picture
   - Update phone number (with PASS인증)
   - Account deletion flow

2. **Implement settings:**
   - Notification preferences
   - Theme selection (light/dark)
   - Privacy settings
   - Logout functionality

#### **Day 5: Favorites & Notifications**
1. **Add favorites system:**
   - Save/remove favorite shops
   - Display favorites list
   - Sync favorites across devices

2. **Implement push notifications:**
   - Configure FCM setup
   - Handle notification permissions
   - Display in-app notifications
   - Handle notification taps and navigation

## 🖥️ **Phase 3: Web Admin Development (Weeks 7-8)**

### **Week 7: Admin Dashboard Setup**

#### **Day 1-2: Project Structure & Authentication**
1. **Set up React admin project:**
   - Configure TypeScript and project structure
   - Install Material-UI for components
   - Set up Supabase client for admin
   - Configure environment variables

2. **Implement admin authentication:**
   - Create admin login screen
   - Implement Supabase auth with admin role checking
   - Set up protected routes
   - Create admin session management

#### **Day 3-4: Dashboard Implementation**
1. **Create super admin dashboard:**
   - Display platform overview metrics
   - Show total users, shops, reservations
   - Add quick action buttons
   - Implement real-time data updates

2. **Create shop admin dashboard:**
   - Show shop-specific metrics
   - Display upcoming reservations
   - Add shop management quick actions
   - Implement shop owner restrictions

#### **Day 5: User Management**
1. **Implement user management:**
   - Create user list with search functionality
   - Add user detail view
   - Implement user status management (suspend/activate)
   - Add basic user editing capabilities

### **Week 8: Shop & Reservation Management**

#### **Day 1-2: Shop Management**
1. **Create shop approval system:**
   - Display pending shop applications
   - Implement shop approval/rejection flow
   - Add document review interface
   - Send approval/rejection notifications

2. **Add shop management:**
   - Edit shop information
   - Manage partnership status
   - Set commission rates
   - View shop performance metrics

#### **Day 3-4: Reservation Management**
1. **Implement reservation overview:**
   - Display all reservations (super admin) or shop reservations (shop admin)
   - Add reservation status management
   - Implement reservation search and filtering
   - Create reservation detail view

2. **Add financial management:**
   - Display payment overview
   - Show platform revenue
   - Manage shop payouts
   - Handle refund processing

#### **Day 5: Points & Settings**
1. **Add points management:**
   - View user point balances
   - Manual point adjustments
   - Referral tracking
   - Influencer management

2. **System settings:**
   - Platform configuration
   - Notification settings
   - Basic system announcements

## 🧪 **Phase 4: Testing & Quality Assurance (Week 9)**

### **Day 1-2: Mobile App Testing**
1. **Unit testing:**
   - Test BLoC state management
   - Test repository functions
   - Test utility functions
   - Test data models

2. **Integration testing:**
   - Test authentication flows
   - Test database operations
   - Test payment integration
   - Test PASS인증 integration

3. **Widget testing:**
   - Test UI components
   - Test navigation flows
   - Test form validations
   - Test error states

### **Day 3-4: Web Admin Testing**
1. **Functionality testing:**
   - Test all admin operations
   - Test role-based access
   - Test data management
   - Test real-time updates

2. **Cross-browser testing:**
   - Test on Chrome, Safari, Firefox
   - Test responsive design
   - Test mobile browser compatibility

### **Day 5: End-to-End Testing**
1. **User flow testing:**
   - Complete user registration to reservation flow
   - Test payment and points system
   - Test admin approval processes
   - Test notification delivery

2. **Performance testing:**
   - Test app performance with large datasets
   - Test image loading and caching
   - Test database query performance
   - Test concurrent user scenarios

## 🚀 **Phase 5: Deployment & Launch (Week 10)**

### **Day 1-2: Production Environment Setup**
1. **Configure production Supabase:**
   - Review and optimize database for production
   - Set up production authentication providers
   - Configure production storage buckets
   - Set up monitoring and alerts

2. **Set up CI/CD pipelines:**
   - Configure GitHub Actions for Flutter app
   - Set up automated testing
   - Configure deployment to app stores
   - Set up web admin deployment pipeline

### **Day 3-4: App Store Deployment**
1. **Android deployment:**
   - Generate signed APK/AAB
   - Create Google Play Console listing
   - Upload app bundle
   - Configure app store optimization (ASO)
   - Submit for review

2. **iOS deployment:**
   - Configure Xcode for production
   - Generate IPA file
   - Create App Store Connect listing
   - Upload to App Store
   - Submit for review

3. **Web admin deployment:**
   - Deploy to Vercel or Netlify
   - Configure custom domain
   - Set up SSL certificates
   - Configure environment variables

### **Day 5: Launch Preparation**
1. **Final testing:**
   - Test production environment
   - Verify all integrations work
   - Test real payments with small amounts
   - Verify notifications are delivered

2. **Launch preparation:**
   - Prepare customer support documentation
   - Set up monitoring and analytics
   - Create user onboarding materials
   - Plan marketing launch strategy

## 📊 **Phase 6: Post-Launch Monitoring (Week 11+)**

### **Immediate Post-Launch (Days 1-7)**
1. **Monitor app performance:**
   - Track crash reports and errors
   - Monitor user registration flow
   - Check payment processing
   - Monitor server performance

2. **Customer support:**
   - Set up support channels
   - Monitor user feedback
   - Address critical issues immediately
   - Document common problems and solutions

### **First Month Monitoring**
1. **Analytics tracking:**
   - User acquisition and retention
   - Feature usage statistics
   - Payment conversion rates
   - Shop onboarding success rates

2. **Performance optimization:**
   - Optimize slow database queries
   - Improve app loading times
   - Optimize image loading
   - Address user experience issues

3. **Feature iteration:**
   - Collect user feedback
   - Prioritize feature improvements
   - Plan next development sprint
   - Prepare for scaling

## 🔧 **Technical Considerations Throughout Development**

### **Security Best Practices**
- Implement proper data validation on all inputs
- Use HTTPS everywhere
- Implement rate limiting
- Secure API keys and secrets
- Regular security audits

### **Performance Optimization**
- Implement proper caching strategies
- Optimize database queries
- Use connection pooling
- Implement image compression
- Monitor and optimize API response times

### **Scalability Planning**
- Design for horizontal scaling
- Implement proper error handling
- Plan for increased database load
- Consider CDN for image delivery
- Monitor resource usage

### **Compliance & Legal**
- Ensure GDPR compliance for user data
- Implement proper data retention policies
- Set up privacy policy and terms of service
- Ensure Korean data protection compliance
- Implement audit trails for sensitive operations

## 📝 **Key Deliverables Checklist**

### **Mobile App Deliverables**
- [ ] Flutter app with all core features
- [ ] Android APK/AAB ready for Play Store
- [ ] iOS IPA ready for App Store
- [ ] User documentation and help guides
- [ ] App store listings and screenshots

### **Web Admin Deliverables**
- [ ] React admin dashboard
- [ ] Deployed web application
- [ ] Admin user documentation
- [ ] System monitoring setup
- [ ] Backup and recovery procedures

### **Backend Deliverables**
- [ ] Supabase database fully configured
- [ ] All APIs tested and documented
- [ ] Production environment configured
- [ ] Monitoring and alerting setup
- [ ] Data backup strategy implemented

### **Business Deliverables**
- [ ] Payment processing fully functional
- [ ] Korean identity verification working
- [ ] Business metrics tracking
- [ ] Customer support system
- [ ] Legal compliance documentation

This comprehensive guide provides the roadmap for developing the Ebeautything MVP from start to finish, ensuring all technical requirements are met while staying true to the PRD specifications. 