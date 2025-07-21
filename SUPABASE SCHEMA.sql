-- =============================================
-- EBEAUTYTHING APP - SUPABASE DATABASE STRUCTURE (MVP)
-- Version: 3.3 - Simplified for MVP (No Social Feed, No Reviews)
-- Based on PRD.txt, Flutter Development Guide, and Web Admin Guide
-- =============================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- =============================================
-- ENUMS
-- =============================================

-- User related enums
CREATE TYPE user_gender AS ENUM ('male', 'female', 'other', 'prefer_not_to_say');
CREATE TYPE user_status AS ENUM ('active', 'inactive', 'suspended', 'deleted');
CREATE TYPE user_role AS ENUM ('user', 'shop_owner', 'admin', 'influencer');
CREATE TYPE social_provider AS ENUM ('kakao', 'apple', 'google', 'email');

-- Shop related enums
CREATE TYPE shop_status AS ENUM ('active', 'inactive', 'pending_approval', 'suspended', 'deleted');
CREATE TYPE shop_type AS ENUM ('partnered', 'non_partnered');
CREATE TYPE service_category AS ENUM ('nail', 'eyelash', 'waxing', 'eyebrow_tattoo', 'hair');
CREATE TYPE shop_verification_status AS ENUM ('pending', 'verified', 'rejected');

-- Reservation related enums
CREATE TYPE reservation_status AS ENUM ('requested', 'confirmed', 'completed', 'cancelled_by_user', 'cancelled_by_shop', 'no_show');
CREATE TYPE payment_status AS ENUM ('pending', 'deposit_paid', 'fully_paid', 'refunded', 'partially_refunded', 'failed');
CREATE TYPE payment_method AS ENUM ('toss_payments', 'kakao_pay', 'naver_pay', 'card', 'bank_transfer');

-- Point related enums
CREATE TYPE point_transaction_type AS ENUM ('earned_service', 'earned_referral', 'used_service', 'expired', 'adjusted', 'influencer_bonus');
CREATE TYPE point_status AS ENUM ('pending', 'available', 'used', 'expired');

-- Notification related enums
CREATE TYPE notification_type AS ENUM ('reservation_confirmed', 'reservation_cancelled', 'point_earned', 'referral_success', 'system');
CREATE TYPE notification_status AS ENUM ('unread', 'read', 'deleted');

-- Admin related enums
CREATE TYPE report_reason AS ENUM ('spam', 'inappropriate_content', 'harassment', 'other');

-- Admin related enums
CREATE TYPE admin_action_type AS ENUM ('user_suspended', 'shop_approved', 'shop_rejected', 'refund_processed', 'points_adjusted');

-- =============================================
-- CORE TABLES
-- =============================================

-- Users table (extends Supabase auth.users)
CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR(255) UNIQUE,
    phone_number VARCHAR(20) UNIQUE,
    phone_verified BOOLEAN DEFAULT FALSE,
    name VARCHAR(100) NOT NULL,
    nickname VARCHAR(50),
    gender user_gender,
    birth_date DATE,
    profile_image_url TEXT,
    user_role user_role DEFAULT 'user',
    user_status user_status DEFAULT 'active',
    is_influencer BOOLEAN DEFAULT FALSE,
    influencer_qualified_at TIMESTAMPTZ,
    social_provider social_provider,
    social_provider_id VARCHAR(255),
    referral_code VARCHAR(20) UNIQUE,
    referred_by_code VARCHAR(20),
    total_points INTEGER DEFAULT 0,
    available_points INTEGER DEFAULT 0,
    total_referrals INTEGER DEFAULT 0,
    successful_referrals INTEGER DEFAULT 0,
    last_login_at TIMESTAMPTZ,
    terms_accepted_at TIMESTAMPTZ,
    privacy_accepted_at TIMESTAMPTZ,
    marketing_consent BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User settings
CREATE TABLE public.user_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    push_notifications_enabled BOOLEAN DEFAULT TRUE,
    reservation_notifications BOOLEAN DEFAULT TRUE,
    event_notifications BOOLEAN DEFAULT TRUE,
    marketing_notifications BOOLEAN DEFAULT FALSE,
    location_tracking_enabled BOOLEAN DEFAULT TRUE,
    language_preference VARCHAR(10) DEFAULT 'ko',
    currency_preference VARCHAR(3) DEFAULT 'KRW',
    theme_preference VARCHAR(20) DEFAULT 'light',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);



-- Shops table
CREATE TABLE public.shops (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    phone_number VARCHAR(20),
    email VARCHAR(255),
    address TEXT NOT NULL,
    detailed_address TEXT,
    postal_code VARCHAR(10),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    location GEOGRAPHY(POINT, 4326),
    shop_type shop_type DEFAULT 'non_partnered',
    shop_status shop_status DEFAULT 'pending_approval',
    verification_status shop_verification_status DEFAULT 'pending',
    business_license_number VARCHAR(50),
    business_license_image_url TEXT,
    main_category service_category NOT NULL,
    sub_categories service_category[],
    operating_hours JSONB, -- {mon: {open: "09:00", close: "18:00", closed: false}, ...}
    payment_methods payment_method[],
    kakao_channel_url TEXT,
    total_bookings INTEGER DEFAULT 0,
    partnership_started_at TIMESTAMPTZ,
    featured_until TIMESTAMPTZ,
    is_featured BOOLEAN DEFAULT FALSE,
    commission_rate DECIMAL(5,2) DEFAULT 10.00, -- Percentage
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Shop images
CREATE TABLE public.shop_images (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shop_id UUID NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    alt_text VARCHAR(255),
    is_primary BOOLEAN DEFAULT FALSE,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Services offered by shops
CREATE TABLE public.shop_services (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shop_id UUID NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category service_category NOT NULL,
    price_min INTEGER, -- in KRW (minimum price)
    price_max INTEGER, -- in KRW (maximum price)
    duration_minutes INTEGER, -- Expected duration
    deposit_amount INTEGER, -- Required deposit amount
    deposit_percentage DECIMAL(5,2), -- Alternative: percentage of total
    is_available BOOLEAN DEFAULT TRUE,
    booking_advance_days INTEGER DEFAULT 30, -- How many days in advance can be booked
    cancellation_hours INTEGER DEFAULT 24, -- Hours before which cancellation is allowed
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Service images
CREATE TABLE public.service_images (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_id UUID NOT NULL REFERENCES public.shop_services(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    alt_text VARCHAR(255),
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- RESERVATION SYSTEM
-- =============================================

-- Reservations
CREATE TABLE public.reservations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    shop_id UUID NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
    reservation_date DATE NOT NULL,
    reservation_time TIME NOT NULL,
    reservation_datetime TIMESTAMPTZ GENERATED ALWAYS AS (
        (reservation_date || ' ' || reservation_time)::TIMESTAMPTZ
    ) STORED,
    status reservation_status DEFAULT 'requested',
    total_amount INTEGER NOT NULL, -- Total service amount in KRW
    deposit_amount INTEGER NOT NULL, -- Deposit paid
    remaining_amount INTEGER, -- Amount to be paid after service
    points_used INTEGER DEFAULT 0,
    points_earned INTEGER DEFAULT 0,
    special_requests TEXT,
    cancellation_reason TEXT,
    no_show_reason TEXT,
    confirmed_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Reserved services (many-to-many between reservations and services)
CREATE TABLE public.reservation_services (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reservation_id UUID NOT NULL REFERENCES public.reservations(id) ON DELETE CASCADE,
    service_id UUID NOT NULL REFERENCES public.shop_services(id) ON DELETE RESTRICT,
    quantity INTEGER DEFAULT 1,
    unit_price INTEGER NOT NULL, -- Price at time of booking
    total_price INTEGER NOT NULL, -- unit_price * quantity
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Payment transactions
CREATE TABLE public.payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reservation_id UUID NOT NULL REFERENCES public.reservations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    payment_method payment_method NOT NULL,
    payment_status payment_status DEFAULT 'pending',
    amount INTEGER NOT NULL, -- Amount in KRW
    currency VARCHAR(3) DEFAULT 'KRW',
    payment_provider VARCHAR(50), -- 'toss_payments', etc.
    provider_transaction_id VARCHAR(255),
    provider_order_id VARCHAR(255),
    is_deposit BOOLEAN DEFAULT TRUE, -- true for deposit, false for remaining amount
    paid_at TIMESTAMPTZ,
    refunded_at TIMESTAMPTZ,
    refund_amount INTEGER DEFAULT 0,
    failure_reason TEXT,
    metadata JSONB, -- Additional payment provider data
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- POINTS SYSTEM
-- =============================================

-- Point transactions
CREATE TABLE public.point_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    reservation_id UUID REFERENCES public.reservations(id) ON DELETE SET NULL,
    transaction_type point_transaction_type NOT NULL,
    amount INTEGER NOT NULL, -- Positive for earning, negative for spending
    description TEXT,
    status point_status DEFAULT 'pending',
    available_from TIMESTAMPTZ, -- When points become available (7 days rule)
    expires_at TIMESTAMPTZ, -- Point expiration date
    related_user_id UUID REFERENCES public.users(id), -- For referral points
    metadata JSONB, -- Additional transaction data
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Point balances (materialized view for performance)
CREATE TABLE public.point_balances (
    user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    total_earned INTEGER DEFAULT 0,
    total_used INTEGER DEFAULT 0,
    available_balance INTEGER DEFAULT 0,
    pending_balance INTEGER DEFAULT 0, -- Points not yet available
    last_calculated_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- FAVORITES
-- =============================================

-- User favorites (shops)
CREATE TABLE public.user_favorites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    shop_id UUID NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, shop_id)
);



-- =============================================
-- NOTIFICATIONS
-- =============================================

-- Notifications
CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    notification_type notification_type NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    status notification_status DEFAULT 'unread',
    related_id UUID, -- ID of related entity (reservation, post, etc.)
    action_url TEXT, -- Deep link URL
    scheduled_for TIMESTAMPTZ,
    sent_at TIMESTAMPTZ,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Push notification tokens
CREATE TABLE public.push_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    platform VARCHAR(20) NOT NULL, -- 'ios', 'android'
    is_active BOOLEAN DEFAULT TRUE,
    last_used_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, token)
);

-- =============================================
-- CONTENT MODERATION & REPORTING
-- =============================================

-- Content reports
CREATE TABLE public.content_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    reported_content_type VARCHAR(50) NOT NULL, -- 'shop', 'user'
    reported_content_id UUID NOT NULL,
    reason report_reason NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'reviewed', 'resolved', 'dismissed'
    reviewed_by UUID REFERENCES public.users(id),
    reviewed_at TIMESTAMPTZ,
    resolution_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- ADMIN & ANALYTICS
-- =============================================

-- Admin actions log
CREATE TABLE public.admin_actions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_id UUID NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
    action_type admin_action_type NOT NULL,
    target_type VARCHAR(50) NOT NULL, -- 'user', 'shop', 'post', etc.
    target_id UUID NOT NULL,
    reason TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- App announcements
CREATE TABLE public.announcements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    is_important BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    target_user_type user_role[], -- Which user types should see this
    starts_at TIMESTAMPTZ DEFAULT NOW(),
    ends_at TIMESTAMPTZ,
    created_by UUID REFERENCES public.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- FAQ
CREATE TABLE public.faqs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category VARCHAR(100) NOT NULL,
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    view_count INTEGER DEFAULT 0,
    helpful_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);



-- =============================================
-- STORAGE BUCKETS CONFIGURATION
-- =============================================

-- Note: These are Supabase Storage bucket configurations
-- Execute these after creating the database structure

/*
-- Profile images bucket
INSERT INTO storage.buckets (id, name, public) VALUES ('profile-images', 'profile-images', true);

-- Shop images bucket
INSERT INTO storage.buckets (id, name, public) VALUES ('shop-images', 'shop-images', true);

-- Service images bucket
INSERT INTO storage.buckets (id, name, public) VALUES ('service-images', 'service-images', true);

-- Business documents bucket (private)
INSERT INTO storage.buckets (id, name, public) VALUES ('business-documents', 'business-documents', false);
*/

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================

-- User indexes
CREATE INDEX idx_users_referral_code ON public.users(referral_code);
CREATE INDEX idx_users_phone_number ON public.users(phone_number);
CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_users_status ON public.users(user_status);

-- Shop indexes
CREATE INDEX idx_shops_location ON public.shops USING GIST(location);
CREATE INDEX idx_shops_status ON public.shops(shop_status);
CREATE INDEX idx_shops_type ON public.shops(shop_type);
CREATE INDEX idx_shops_category ON public.shops(main_category);

-- Reservation indexes
CREATE INDEX idx_reservations_user_id ON public.reservations(user_id);
CREATE INDEX idx_reservations_shop_id ON public.reservations(shop_id);
CREATE INDEX idx_reservations_datetime ON public.reservations(reservation_datetime);
CREATE INDEX idx_reservations_status ON public.reservations(status);
CREATE INDEX idx_reservations_date_status ON public.reservations(reservation_date, status);

-- Point transaction indexes
CREATE INDEX idx_point_transactions_user_id ON public.point_transactions(user_id);
CREATE INDEX idx_point_transactions_type ON public.point_transactions(transaction_type);
CREATE INDEX idx_point_transactions_status ON public.point_transactions(status);
CREATE INDEX idx_point_transactions_available_from ON public.point_transactions(available_from);



-- Notification indexes
CREATE INDEX idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX idx_notifications_status ON public.notifications(status);
CREATE INDEX idx_notifications_type ON public.notifications(notification_type);

-- =============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.point_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Basic RLS policies (more specific policies should be added based on requirements)

-- Users can read their own data
CREATE POLICY "Users can read own data" ON public.users
    FOR SELECT USING (auth.uid() = id);

-- Users can update their own data
CREATE POLICY "Users can update own data" ON public.users
    FOR UPDATE USING (auth.uid() = id);

-- Users can read their own settings
CREATE POLICY "Users can manage own settings" ON public.user_settings
    FOR ALL USING (auth.uid() = user_id);

-- Public can read active shops
CREATE POLICY "Public can read active shops" ON public.shops
    FOR SELECT USING (shop_status = 'active');

-- Shop owners can manage their shops
CREATE POLICY "Shop owners can manage own shops" ON public.shops
    FOR ALL USING (auth.uid() = owner_id);

-- Users can read their own reservations
CREATE POLICY "Users can read own reservations" ON public.reservations
    FOR SELECT USING (auth.uid() = user_id);

-- Shop owners can read reservations for their shops
CREATE POLICY "Shop owners can read shop reservations" ON public.reservations
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.shops 
            WHERE shops.id = reservations.shop_id 
            AND shops.owner_id = auth.uid()
        )
    );

-- Users can read their own point transactions
CREATE POLICY "Users can read own point transactions" ON public.point_transactions
    FOR SELECT USING (auth.uid() = user_id);

-- Users can read their own notifications
CREATE POLICY "Users can read own notifications" ON public.notifications
    FOR SELECT USING (auth.uid() = user_id);

-- =============================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- =============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to relevant tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_settings_updated_at BEFORE UPDATE ON public.user_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_shops_updated_at BEFORE UPDATE ON public.shops
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reservations_updated_at BEFORE UPDATE ON public.reservations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to update user point balances
CREATE OR REPLACE FUNCTION update_user_points()
RETURNS TRIGGER AS $$
BEGIN
    -- Update user's total and available points
    UPDATE public.users SET
        total_points = (
            SELECT COALESCE(SUM(amount), 0) 
            FROM public.point_transactions 
            WHERE user_id = NEW.user_id 
            AND amount > 0 
            AND status = 'available'
        ),
        available_points = (
            SELECT COALESCE(SUM(amount), 0) 
            FROM public.point_transactions 
            WHERE user_id = NEW.user_id 
            AND status = 'available'
            AND (available_from IS NULL OR available_from <= NOW())
            AND (expires_at IS NULL OR expires_at > NOW())
        )
    WHERE id = NEW.user_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update point balances
CREATE TRIGGER update_point_balances_trigger 
    AFTER INSERT OR UPDATE ON public.point_transactions
    FOR EACH ROW EXECUTE FUNCTION update_user_points();



-- =============================================
-- FUNCTIONS FOR BUSINESS LOGIC
-- =============================================

-- Function to generate unique referral code
CREATE OR REPLACE FUNCTION generate_referral_code()
RETURNS TEXT AS $$
DECLARE
    chars TEXT := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    result TEXT := '';
    i INTEGER;
BEGIN
    FOR i IN 1..8 LOOP
        result := result || substr(chars, floor(random() * length(chars) + 1)::integer, 1);
    END LOOP;
    
    -- Check if code already exists
    IF EXISTS (SELECT 1 FROM public.users WHERE referral_code = result) THEN
        RETURN generate_referral_code(); -- Recursive call if collision
    END IF;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to check and update influencer status
CREATE OR REPLACE FUNCTION check_influencer_status(user_uuid UUID)
RETURNS BOOLEAN AS $$
DECLARE
    referral_count INTEGER;
    paid_referral_count INTEGER;
BEGIN
    -- Count total referrals
    SELECT COUNT(*) INTO referral_count
    FROM public.users 
    WHERE referred_by_code = (
        SELECT referral_code FROM public.users WHERE id = user_uuid
    );
    
    -- Count referrals who have made at least one payment
    SELECT COUNT(DISTINCT u.id) INTO paid_referral_count
    FROM public.users u
    JOIN public.payments p ON u.id = p.user_id
    WHERE u.referred_by_code = (
        SELECT referral_code FROM public.users WHERE id = user_uuid
    ) AND p.payment_status = 'fully_paid';
    
    -- Update influencer status if qualified
    IF referral_count >= 50 AND paid_referral_count >= 50 THEN
        UPDATE public.users SET
            is_influencer = TRUE,
            influencer_qualified_at = NOW(),
            user_role = 'influencer'
        WHERE id = user_uuid AND NOT is_influencer;
        
        RETURN TRUE;
    END IF;
    
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate and award points
CREATE OR REPLACE FUNCTION award_service_points(reservation_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
    total_amount INTEGER;
    user_uuid UUID;
    points_to_award INTEGER;
    max_eligible_amount INTEGER := 300000; -- 30만원 한도
    point_rate DECIMAL := 0.025; -- 2.5%
BEGIN
    -- Get reservation details
    SELECT r.total_amount, r.user_id INTO total_amount, user_uuid
    FROM public.reservations r
    WHERE r.id = reservation_uuid;
    
    -- Calculate points (capped at 300,000 KRW)
    points_to_award := FLOOR(
        LEAST(total_amount, max_eligible_amount) * point_rate
    );
    
    -- Insert point transaction
    INSERT INTO public.point_transactions (
        user_id,
        reservation_id,
        transaction_type,
        amount,
        description,
        status,
        available_from
    ) VALUES (
        user_uuid,
        reservation_uuid,
        'earned_service',
        points_to_award,
        '서비스 이용 적립',
        'pending',
        NOW() + INTERVAL '7 days'
    );
    
    RETURN points_to_award;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- INITIAL DATA
-- =============================================

-- Insert default admin user (should be updated with real admin credentials)
INSERT INTO public.users (
    id,
    email,
    name,
    user_role,
    user_status,
    referral_code,
    created_at
) VALUES (
    '00000000-0000-0000-0000-000000000001'::UUID,
    'admin@ebeautything.com',
    'System Admin',
    'admin',
    'active',
    'ADMIN001',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Insert FAQ categories and common questions
INSERT INTO public.faqs (category, question, answer, display_order) VALUES
('예약', '예약을 취소하고 싶어요', '예약 시간 24시간 전까지는 100% 환불이 가능합니다. 마이예약에서 취소 버튼을 눌러주세요.', 1),
('예약', '예약금은 얼마인가요?', '예약금은 샵과 서비스에 따라 다르며, 보통 전체 금액의 20-30% 정도입니다.', 2),
('포인트', '포인트는 언제 사용할 수 있나요?', '포인트는 적립된 날로부터 7일 후에 사용 가능합니다.', 1),
('포인트', '포인트 적립률은 얼마인가요?', '서비스 이용 금액의 2.5%가 포인트로 적립됩니다. (최대 30만원까지)', 2),
('계정', '회원탈퇴는 어떻게 하나요?', '마이페이지 > 설정 > 회원탈퇴에서 진행할 수 있습니다.', 1);

-- Insert service categories data
INSERT INTO public.announcements (title, content, is_important, target_user_type) VALUES
('에뷰리띵 앱 출시!', '에뷰리띵 앱이 정식 출시되었습니다. 다양한 혜택을 확인해보세요!', true, ARRAY['user'::user_role]);

-- =============================================
-- VIEWS FOR COMMON QUERIES
-- =============================================

-- View for user point summary
CREATE VIEW user_point_summary AS
SELECT 
    u.id as user_id,
    u.name,
    u.total_points,
    u.available_points,
    COALESCE(pending.pending_points, 0) as pending_points,
    COALESCE(recent.points_this_month, 0) as points_this_month
FROM public.users u
LEFT JOIN (
    SELECT 
        user_id,
        SUM(amount) as pending_points
    FROM public.point_transactions 
    WHERE status = 'pending'
    GROUP BY user_id
) pending ON u.id = pending.user_id
LEFT JOIN (
    SELECT 
        user_id,
        SUM(amount) as points_this_month
    FROM public.point_transactions 
    WHERE status = 'available'
    AND amount > 0
    AND created_at >= date_trunc('month', NOW())
    GROUP BY user_id
) recent ON u.id = recent.user_id;

-- View for shop performance summary
CREATE VIEW shop_performance_summary AS
SELECT 
    s.id as shop_id,
    s.name,
    s.shop_status,
    s.shop_type,
    s.total_bookings,
    COALESCE(recent.bookings_this_month, 0) as bookings_this_month,
    COALESCE(revenue.total_revenue, 0) as total_revenue
FROM public.shops s
LEFT JOIN (
    SELECT 
        shop_id,
        COUNT(*) as bookings_this_month
    FROM public.reservations
    WHERE status IN ('confirmed', 'completed')
    AND created_at >= date_trunc('month', NOW())
    GROUP BY shop_id
) recent ON s.id = recent.shop_id
LEFT JOIN (
    SELECT 
        r.shop_id,
        SUM(r.total_amount) as total_revenue
    FROM public.reservations r
    WHERE r.status = 'completed'
    GROUP BY r.shop_id
) revenue ON s.id = revenue.shop_id;

-- =============================================
-- ADMIN VIEWS FOR WEB DASHBOARD
-- =============================================

-- Admin view for user management
CREATE VIEW admin_users_summary AS
SELECT 
    id,
    name,
    email,
    phone_number,
    user_status,
    user_role,
    is_influencer,
    total_points,
    total_referrals,
    created_at
FROM public.users
ORDER BY created_at DESC;

-- Admin view for shop management  
CREATE VIEW admin_shops_summary AS
SELECT 
    s.id,
    s.name,
    s.shop_status,
    s.shop_type,
    s.main_category,
    s.total_bookings,
    u.name as owner_name,
    u.email as owner_email,
    s.created_at
FROM public.shops s
LEFT JOIN public.users u ON s.owner_id = u.id
ORDER BY s.created_at DESC;

-- Admin view for reservations
CREATE VIEW admin_reservations_summary AS
SELECT 
    r.id,
    r.reservation_date,
    r.reservation_time,
    r.status,
    r.total_amount,
    u.name as customer_name,
    u.phone_number as customer_phone,
    s.name as shop_name,
    r.created_at
FROM public.reservations r
JOIN public.users u ON r.user_id = u.id
JOIN public.shops s ON r.shop_id = s.id
ORDER BY r.reservation_date DESC, r.reservation_time DESC;

-- =============================================
-- END OF SIMPLIFIED DATABASE STRUCTURE
-- ============================================= 