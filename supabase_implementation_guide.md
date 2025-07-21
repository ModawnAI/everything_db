# Ebeautything App - Supabase Database Implementation Guide

## Overview

This document provides a comprehensive guide for implementing the Supabase database structure for the Ebeautything beauty service booking app (v3.2). The structure is designed to support all features outlined in the PRD.txt including user management, shop listings, reservations, points system, social features, and admin capabilities.

## 🏗️ Database Structure Overview

### Core Entities

1. **Users & Authentication**
   - Extended user profiles with social login support
   - Phone verification system
   - Referral code system with influencer rewards
   - Comprehensive user settings and preferences

2. **Shops & Services**
   - Partnered vs non-partnered shop distinction
   - Location-based search with PostGIS
   - Service catalog with pricing and availability
   - Image galleries and business verification

3. **Reservation System**
   - Two-step booking process (deposit + remaining payment)
   - Service selection with time slots
   - Status tracking from request to completion
   - Cancellation and refund handling

4. **Points & Rewards**
   - 2.5% cashback system with 7-day availability rule
   - Referral rewards with influencer bonuses (2x)
   - Transaction history and balance tracking
   - Expiration and adjustment handling

5. **Social Features**
   - Instagram-style feed with image posts
   - Shop tagging and location sharing
   - Reviews and ratings system
   - Like and comment functionality

6. **Admin & Moderation**
   - Content reporting and moderation
   - Admin action logging
   - Announcements and FAQ management
   - Analytics and performance tracking

## 📊 Key ENUMs Defined

### User Management
- `user_gender`: male, female, other, prefer_not_to_say
- `user_status`: active, inactive, suspended, deleted
- `user_role`: user, shop_owner, admin, influencer
- `social_provider`: kakao, apple, google, email

### Shop Management
- `shop_status`: active, inactive, pending_approval, suspended, deleted
- `shop_type`: partnered, non_partnered
- `service_category`: nail, eyelash, waxing, eyebrow_tattoo, hair
- `shop_verification_status`: pending, verified, rejected

### Reservations & Payments
- `reservation_status`: requested, confirmed, completed, cancelled_by_user, cancelled_by_shop, no_show
- `payment_status`: pending, deposit_paid, fully_paid, refunded, partially_refunded, failed
- `payment_method`: toss_payments, kakao_pay, naver_pay, card, bank_transfer

### Points System
- `point_transaction_type`: earned_service, earned_referral, used_service, expired, adjusted, influencer_bonus
- `point_status`: pending, available, used, expired

## 🔧 Setup Instructions

### 1. Create the Database Structure

```bash
# Run the main structure file
psql -h your-supabase-host -U postgres -d postgres -f supabase_database_structure.sql
```

### 2. Configure Storage Buckets

```sql
-- Execute these commands in the Supabase SQL editor

-- Profile images bucket (public)
INSERT INTO storage.buckets (id, name, public) 
VALUES ('profile-images', 'profile-images', true);

-- Shop images bucket (public)
INSERT INTO storage.buckets (id, name, public) 
VALUES ('shop-images', 'shop-images', true);

-- Service images bucket (public)
INSERT INTO storage.buckets (id, name, public) 
VALUES ('service-images', 'service-images', true);

-- Review images bucket (public)
INSERT INTO storage.buckets (id, name, public) 
VALUES ('review-images', 'review-images', true);

-- Post images bucket (public)
INSERT INTO storage.buckets (id, name, public) 
VALUES ('post-images', 'post-images', true);

-- Business documents bucket (private)
INSERT INTO storage.buckets (id, name, public) 
VALUES ('business-documents', 'business-documents', false);
```

### 3. Configure Storage Policies

```sql
-- Allow authenticated users to upload their profile images
CREATE POLICY "Users can upload own profile images" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'profile-images' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow public read access to profile images
CREATE POLICY "Public can view profile images" ON storage.objects
FOR SELECT USING (bucket_id = 'profile-images');

-- Similar policies for other buckets...
```

### 4. Set up Authentication

```sql
-- Configure auth settings in Supabase dashboard:
-- 1. Enable email signup
-- 2. Configure social providers (Kakao, Apple, Google)
-- 3. Set up phone authentication
-- 4. Configure JWT settings
```

## 🚀 Key Features Implementation

### 1. User Registration & Referral System

```sql
-- Automatic referral code generation on user creation
CREATE OR REPLACE FUNCTION generate_user_referral_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.referral_code IS NULL THEN
        NEW.referral_code := generate_referral_code();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER generate_referral_code_trigger
    BEFORE INSERT ON public.users
    FOR EACH ROW EXECUTE FUNCTION generate_user_referral_code();
```

### 2. Location-Based Shop Search

```sql
-- Find shops within radius (using PostGIS)
SELECT s.*, 
       ST_Distance(location, ST_MakePoint($longitude, $latitude)::geography) as distance
FROM public.shops s
WHERE ST_DWithin(location, ST_MakePoint($longitude, $latitude)::geography, $radius_in_meters)
  AND shop_status = 'active'
ORDER BY 
  CASE WHEN shop_type = 'partnered' THEN 0 ELSE 1 END,
  partnership_started_at DESC,
  distance;
```

### 3. Points System Logic

```sql
-- Award points after service completion
SELECT award_service_points('reservation-uuid-here');

-- Check available points for user
SELECT SUM(amount) as available_points
FROM public.point_transactions
WHERE user_id = $user_id
  AND status = 'available'
  AND (available_from IS NULL OR available_from <= NOW())
  AND (expires_at IS NULL OR expires_at > NOW());
```

### 4. Influencer Status Automation

```sql
-- Check and update influencer status
SELECT check_influencer_status('user-uuid-here');
```

## 📱 Mobile App Integration

### Authentication Flow
1. **Social Login**: Use Supabase Auth with configured providers
2. **Phone Verification**: Store verification codes in `user_verifications` table
3. **Profile Completion**: Update `users` table with additional info
4. **Referral Processing**: Link referred users via `referred_by_code`

### Push Notifications
1. **Token Management**: Store FCM/APNs tokens in `push_tokens` table
2. **Notification Creation**: Insert into `notifications` table
3. **Delivery Tracking**: Update `sent_at` and `read_at` timestamps

### Real-time Features
1. **Reservation Updates**: Use Supabase real-time subscriptions
2. **New Posts**: Subscribe to `posts` table changes
3. **Notifications**: Real-time notification delivery

## 🔐 Security Considerations

### Row Level Security (RLS)
- All tables have RLS enabled with appropriate policies
- Users can only access their own data
- Shop owners can manage their shop data
- Public data (shops, reviews) is accessible to all authenticated users

### Data Privacy
- Personal information is protected by RLS
- Phone numbers and emails are handled securely
- Business documents are stored in private buckets

### API Security
- Use Supabase service role key for admin operations
- Implement rate limiting for public endpoints
- Validate all user inputs on the client side

## 📈 Analytics & Monitoring

### User Analytics
- Track user sessions in `user_sessions` table
- Monitor app usage patterns
- Analyze user engagement metrics

### Business Analytics
- Shop performance tracking via `shop_performance_summary` view
- Revenue and booking analytics
- Point system usage monitoring

### System Health
- Monitor failed payments
- Track user complaints and reports
- Analyze system performance metrics

## 🛠️ Maintenance & Operations

### Regular Tasks
1. **Point Expiration**: Set up cron job to expire old points
2. **Influencer Status**: Periodically check and update influencer qualifications
3. **Analytics Updates**: Refresh materialized views for performance
4. **Cleanup**: Remove old sessions and expired verification codes

### Backup Strategy
1. **Daily Backups**: Automated database backups
2. **Storage Backups**: Regular file storage backups
3. **Point-in-time Recovery**: Enable for critical data recovery

### Scaling Considerations
1. **Database Indexing**: Monitor and optimize query performance
2. **Connection Pooling**: Use pgBouncer for connection management
3. **Read Replicas**: Consider for heavy read workloads
4. **Caching**: Implement Redis for frequently accessed data

## 📋 Migration and Deployment

### Development Environment
```bash
# Set up local development with Supabase CLI
supabase init
supabase db start
supabase db reset --with-seed
```

### Production Deployment
1. **Environment Setup**: Configure production Supabase project
2. **Migration Execution**: Run database structure script
3. **Data Seeding**: Add initial data (admin user, FAQs, etc.)
4. **Testing**: Comprehensive testing of all features
5. **Monitoring**: Set up alerts and monitoring

### Data Migration (if from existing system)
1. **User Data**: Migrate existing user accounts
2. **Shop Data**: Import shop listings and services
3. **Transaction History**: Preserve booking and payment records
4. **Content Migration**: Transfer reviews and posts

## 🔄 API Integration Points

### Toss Payments Integration
- Store payment records in `payments` table
- Handle webhooks for payment status updates
- Manage refunds and cancellations

### Social Login Integration
- Configure OAuth providers in Supabase Auth
- Map social profile data to user fields
- Handle account linking scenarios

### Push Notification Services
- FCM for Android notifications
- APNs for iOS notifications
- Store device tokens securely

## 📚 Additional Resources

### Supabase Documentation
- [Auth Documentation](https://supabase.com/docs/guides/auth)
- [Database Documentation](https://supabase.com/docs/guides/database)
- [Storage Documentation](https://supabase.com/docs/guides/storage)
- [Real-time Documentation](https://supabase.com/docs/guides/realtime)

### Performance Optimization
- Use prepared statements for frequent queries
- Implement proper indexing strategy
- Monitor slow query logs
- Use database query optimization tools

This comprehensive database structure provides a solid foundation for the Ebeautything app, supporting all features outlined in the PRD while maintaining security, performance, and scalability. 