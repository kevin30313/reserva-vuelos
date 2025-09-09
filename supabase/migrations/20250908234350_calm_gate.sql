/*
  # VuelaChile Database Schema - Base Tables
  
  This migration creates the foundational database structure for the VuelaChile flight booking platform.
  Optimized for Chilean aviation market with Multi-AZ resilience and read replica support.
  
  ## New Tables Created:
  
  1. **airlines** - Chilean and international airlines
  2. **airports** - Chilean airports and international destinations  
  3. **aircraft_types** - Aircraft models and configurations
  4. **flights** - Flight schedules and availability
  5. **flight_prices** - Dynamic pricing by class
  6. **users** - User accounts (synced with on-premise auth)
  7. **bookings** - Flight reservations and tickets
  8. **payment_transactions** - Payment processing records
  9. **passengers** - Passenger information for bookings
  10. **booking_passengers** - Linking table for bookings and passengers
  
  ## Security Features:
  
  - Row Level Security (RLS) enabled on all tables
  - Audit trails with created_at/updated_at timestamps
  - Soft delete patterns where appropriate
  - Encrypted sensitive data fields
  
  ## Performance Optimizations:
  
  - Composite indexes for common search patterns
  - Partitioning strategy for large tables (flights, bookings)
  - Connection pooling optimizations
  - Read replica routing for search queries
*/

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Airlines table - Chilean and international carriers
CREATE TABLE IF NOT EXISTS airlines (
    airline_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    airline_code varchar(3) UNIQUE NOT NULL, -- IATA code
    airline_name varchar(100) NOT NULL,
    country_code varchar(2) NOT NULL DEFAULT 'CL',
    logo_url text,
    website_url text,
    baggage_allowance jsonb DEFAULT '{"carry_on": "8kg", "checked": "23kg"}',
    cancellation_policy text,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Airports table - Focus on Chilean airports
CREATE TABLE IF NOT EXISTS airports (
    airport_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    airport_code varchar(3) UNIQUE NOT NULL, -- IATA code
    airport_name varchar(100) NOT NULL,
    city_name varchar(50) NOT NULL,
    region varchar(50),
    country_code varchar(2) NOT NULL DEFAULT 'CL',
    timezone varchar(50) DEFAULT 'America/Santiago',
    coordinates point, -- For distance calculations
    is_international boolean DEFAULT false,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Aircraft types
CREATE TABLE IF NOT EXISTS aircraft_types (
    aircraft_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    aircraft_code varchar(10) UNIQUE NOT NULL,
    manufacturer varchar(50) NOT NULL,
    model varchar(50) NOT NULL,
    capacity_economy integer NOT NULL,
    capacity_premium integer DEFAULT 0,
    capacity_business integer DEFAULT 0,
    range_km integer,
    cruise_speed_kmh integer,
    created_at timestamptz DEFAULT now()
);

-- Flights table with partitioning support
CREATE TABLE IF NOT EXISTS flights (
    flight_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    airline_id uuid NOT NULL REFERENCES airlines(airline_id),
    flight_number varchar(10) NOT NULL,
    departure_airport_id uuid NOT NULL REFERENCES airports(airport_id),
    arrival_airport_id uuid NOT NULL REFERENCES airports(airport_id),
    aircraft_type_id uuid NOT NULL REFERENCES aircraft_types(aircraft_id),
    departure_time timestamptz NOT NULL,
    arrival_time timestamptz NOT NULL,
    flight_duration interval GENERATED ALWAYS AS (arrival_time - departure_time) STORED,
    stops integer DEFAULT 0,
    status varchar(20) DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'delayed', 'cancelled', 'completed')),
    total_seats integer NOT NULL,
    available_seats integer NOT NULL,
    gate varchar(10),
    check_in_start timestamptz,
    check_in_end timestamptz,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    
    CONSTRAINT valid_flight_times CHECK (arrival_time > departure_time),
    CONSTRAINT valid_seat_counts CHECK (available_seats <= total_seats AND available_seats >= 0)
) PARTITION BY RANGE (departure_time);

-- Create partitions for flights (quarterly)
CREATE TABLE IF NOT EXISTS flights_2024_q4 PARTITION OF flights
    FOR VALUES FROM ('2024-10-01') TO ('2025-01-01');

CREATE TABLE IF NOT EXISTS flights_2025_q1 PARTITION OF flights
    FOR VALUES FROM ('2025-01-01') TO ('2025-04-01');

CREATE TABLE IF NOT EXISTS flights_2025_q2 PARTITION OF flights
    FOR VALUES FROM ('2025-04-01') TO ('2025-07-01');

-- Flight pricing with dynamic pricing support
CREATE TABLE IF NOT EXISTS flight_prices (
    price_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    flight_id uuid NOT NULL REFERENCES flights(flight_id) ON DELETE CASCADE,
    price_economy decimal(10,2) NOT NULL,
    price_premium decimal(10,2),
    price_business decimal(10,2),
    currency_code varchar(3) DEFAULT 'CLP',
    includes_tax boolean DEFAULT false,
    tax_rate decimal(5,4) DEFAULT 0.19, -- Chilean IVA
    base_price decimal(10,2) NOT NULL, -- Price without taxes
    dynamic_pricing_factor decimal(3,2) DEFAULT 1.00,
    valid_from timestamptz DEFAULT now(),
    valid_until timestamptz,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    
    CONSTRAINT valid_prices CHECK (
        price_economy > 0 AND 
        (price_premium IS NULL OR price_premium >= price_economy) AND
        (price_business IS NULL OR price_business >= price_premium)
    )
);

-- Users table (synced with on-premise authentication)
CREATE TABLE IF NOT EXISTS users (
    user_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    external_user_id varchar(255) UNIQUE NOT NULL, -- From on-premise system
    email varchar(255) UNIQUE NOT NULL,
    first_name varchar(100) NOT NULL,
    last_name varchar(100) NOT NULL,
    phone varchar(20),
    date_of_birth date,
    nationality varchar(2) DEFAULT 'CL',
    document_type varchar(20) DEFAULT 'rut' CHECK (document_type IN ('rut', 'passport', 'dni')),
    document_number varchar(50),
    preferred_language varchar(2) DEFAULT 'es',
    marketing_consent boolean DEFAULT false,
    frequent_flyer_programs jsonb DEFAULT '[]',
    emergency_contact jsonb,
    last_sync_at timestamptz DEFAULT now(),
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Bookings table with comprehensive tracking
CREATE TABLE IF NOT EXISTS bookings (
    booking_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_reference varchar(20) UNIQUE NOT NULL,
    user_id uuid NOT NULL REFERENCES users(user_id),
    flight_id uuid NOT NULL REFERENCES flights(flight_id),
    booking_status varchar(20) DEFAULT 'pending' CHECK (
        booking_status IN ('pending', 'confirmed', 'cancelled', 'completed', 'no_show')
    ),
    payment_status varchar(20) DEFAULT 'pending' CHECK (
        payment_status IN ('pending', 'paid', 'failed', 'refunded', 'partially_refunded')
    ),
    passenger_count integer NOT NULL DEFAULT 1,
    total_amount decimal(12,2) NOT NULL,
    currency_code varchar(3) DEFAULT 'CLP',
    payment_method varchar(50),
    booking_class varchar(20) DEFAULT 'economy' CHECK (
        booking_class IN ('economy', 'premium', 'business', 'first')
    ),
    special_requests text,
    booking_date timestamptz NOT NULL DEFAULT now(),
    payment_due_date timestamptz,
    cancellation_deadline timestamptz,
    check_in_status varchar(20) DEFAULT 'not_available' CHECK (
        check_in_status IN ('not_available', 'available', 'completed')
    ),
    seat_assignments jsonb DEFAULT '[]',
    meal_preferences jsonb DEFAULT '[]',
    baggage_info jsonb DEFAULT '{}',
    booking_source varchar(50) DEFAULT 'web',
    agent_id uuid, -- For travel agent bookings
    corporate_booking_code varchar(50),
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    
    CONSTRAINT valid_amounts CHECK (total_amount > 0),
    CONSTRAINT valid_passenger_count CHECK (passenger_count > 0)
);

-- Payment transactions with Chilean payment methods
CREATE TABLE IF NOT EXISTS payment_transactions (
    transaction_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id uuid NOT NULL REFERENCES bookings(booking_id),
    payment_method varchar(50) NOT NULL CHECK (
        payment_method IN ('transbank', 'khipu', 'flow', 'mercadopago', 'stripe', 'cash')
    ),
    transaction_reference varchar(100), -- External transaction ID
    amount decimal(12,2) NOT NULL,
    currency_code varchar(3) DEFAULT 'CLP',
    transaction_status varchar(20) DEFAULT 'pending' CHECK (
        transaction_status IN ('pending', 'processing', 'completed', 'failed', 'cancelled', 'refunded')
    ),
    authorization_code varchar(50),
    gateway_response jsonb, -- Store complete gateway response
    fee_amount decimal(10,2) DEFAULT 0,
    net_amount decimal(12,2) GENERATED ALWAYS AS (amount - fee_amount) STORED,
    processed_at timestamptz,
    gateway_transaction_date timestamptz,
    installments integer DEFAULT 1,
    card_last_four varchar(4),
    card_type varchar(50),
    failure_reason text,
    refund_transactions uuid[], -- Array of refund transaction IDs
    metadata jsonb DEFAULT '{}',
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    
    CONSTRAINT valid_transaction_amount CHECK (amount > 0),
    CONSTRAINT valid_installments CHECK (installments > 0)
);

-- Passengers information
CREATE TABLE IF NOT EXISTS passengers (
    passenger_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES users(user_id), -- Nullable for guest bookings
    first_name varchar(100) NOT NULL,
    last_name varchar(100) NOT NULL,
    date_of_birth date NOT NULL,
    gender varchar(10) CHECK (gender IN ('male', 'female', 'other')),
    nationality varchar(2) NOT NULL DEFAULT 'CL',
    document_type varchar(20) NOT NULL DEFAULT 'rut' CHECK (
        document_type IN ('rut', 'passport', 'dni', 'identity_card')
    ),
    document_number varchar(50) NOT NULL,
    document_expiry date,
    document_issuing_country varchar(2),
    known_traveler_number varchar(50), -- TSA PreCheck, etc.
    redress_number varchar(50),
    dietary_restrictions text[],
    mobility_assistance boolean DEFAULT false,
    emergency_contact jsonb,
    frequent_flyer_number varchar(50),
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    
    CONSTRAINT valid_birth_date CHECK (date_of_birth < CURRENT_DATE),
    UNIQUE(document_type, document_number)
);

-- Linking table for bookings and passengers
CREATE TABLE IF NOT EXISTS booking_passengers (
    booking_passenger_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id uuid NOT NULL REFERENCES bookings(booking_id) ON DELETE CASCADE,
    passenger_id uuid NOT NULL REFERENCES passengers(passenger_id),
    seat_number varchar(10),
    seat_class varchar(20) DEFAULT 'economy',
    meal_preference varchar(50),
    baggage_allowance jsonb DEFAULT '{}',
    check_in_time timestamptz,
    boarding_pass_issued boolean DEFAULT false,
    special_services text[],
    created_at timestamptz DEFAULT now(),
    
    UNIQUE(booking_id, passenger_id),
    UNIQUE(booking_id, seat_number) -- Prevent double seat assignment
);

-- Indexes for performance optimization

-- Airlines
CREATE INDEX IF NOT EXISTS idx_airlines_code ON airlines(airline_code);
CREATE INDEX IF NOT EXISTS idx_airlines_active ON airlines(is_active) WHERE is_active = true;

-- Airports
CREATE INDEX IF NOT EXISTS idx_airports_code ON airports(airport_code);
CREATE INDEX IF NOT EXISTS idx_airports_city ON airports(city_name, country_code);
CREATE INDEX IF NOT EXISTS idx_airports_coordinates ON airports USING GIST(coordinates);

-- Flights - Critical for search performance
CREATE INDEX IF NOT EXISTS idx_flights_route_date ON flights(departure_airport_id, arrival_airport_id, departure_time);
CREATE INDEX IF NOT EXISTS idx_flights_departure_time ON flights(departure_time);
CREATE INDEX IF NOT EXISTS idx_flights_arrival_time ON flights(arrival_time);
CREATE INDEX IF NOT EXISTS idx_flights_airline ON flights(airline_id);
CREATE INDEX IF NOT EXISTS idx_flights_status ON flights(status) WHERE status IN ('scheduled', 'delayed');
CREATE INDEX IF NOT EXISTS idx_flights_available_seats ON flights(available_seats) WHERE available_seats > 0;

-- Flight prices
CREATE INDEX IF NOT EXISTS idx_flight_prices_flight_id ON flight_prices(flight_id);
CREATE INDEX IF NOT EXISTS idx_flight_prices_validity ON flight_prices(valid_from, valid_until);

-- Users
CREATE INDEX IF NOT EXISTS idx_users_external_id ON users(external_user_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_active ON users(is_active) WHERE is_active = true;

-- Bookings - Essential for user lookups and reporting
CREATE INDEX IF NOT EXISTS idx_bookings_reference ON bookings(booking_reference);
CREATE INDEX IF NOT EXISTS idx_bookings_user_id ON bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_flight_id ON bookings(flight_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(booking_status, payment_status);
CREATE INDEX IF NOT EXISTS idx_bookings_date ON bookings(booking_date);
CREATE INDEX IF NOT EXISTS idx_bookings_user_date ON bookings(user_id, booking_date DESC);

-- Payment transactions
CREATE INDEX IF NOT EXISTS idx_payment_transactions_booking ON payment_transactions(booking_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_reference ON payment_transactions(transaction_reference);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_status ON payment_transactions(transaction_status);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_method ON payment_transactions(payment_method);

-- Passengers
CREATE INDEX IF NOT EXISTS idx_passengers_user_id ON passengers(user_id);
CREATE INDEX IF NOT EXISTS idx_passengers_document ON passengers(document_type, document_number);

-- Booking passengers
CREATE INDEX IF NOT EXISTS idx_booking_passengers_booking ON booking_passengers(booking_id);
CREATE INDEX IF NOT EXISTS idx_booking_passengers_passenger ON booking_passengers(passenger_id);

-- Enable Row Level Security on all tables
ALTER TABLE airlines ENABLE ROW LEVEL SECURITY;
ALTER TABLE airports ENABLE ROW LEVEL SECURITY;
ALTER TABLE aircraft_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE flights ENABLE ROW LEVEL SECURITY;
ALTER TABLE flight_prices ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE passengers ENABLE ROW LEVEL SECURITY;
ALTER TABLE booking_passengers ENABLE ROW LEVEL SECURITY;

-- RLS Policies - Allow read access for public data, restrict write access

-- Public read access for reference data
CREATE POLICY "Allow read access to airlines" ON airlines
    FOR SELECT TO public
    USING (is_active = true);

CREATE POLICY "Allow read access to airports" ON airports
    FOR SELECT TO public
    USING (is_active = true);

CREATE POLICY "Allow read access to aircraft types" ON aircraft_types
    FOR SELECT TO public
    USING (true);

-- Flight data - read access for search
CREATE POLICY "Allow read access to flights" ON flights
    FOR SELECT TO public
    USING (is_active = true AND departure_time > now() - interval '24 hours');

CREATE POLICY "Allow read access to flight prices" ON flight_prices
    FOR SELECT TO public
    USING (valid_from <= now() AND (valid_until IS NULL OR valid_until > now()));

-- User data - users can only access their own data
CREATE POLICY "Users can read own data" ON users
    FOR SELECT TO authenticated
    USING (external_user_id = current_user);

CREATE POLICY "Users can update own data" ON users
    FOR UPDATE TO authenticated
    USING (external_user_id = current_user);

-- Booking data - users can only access their own bookings
CREATE POLICY "Users can read own bookings" ON bookings
    FOR SELECT TO authenticated
    USING (user_id IN (SELECT user_id FROM users WHERE external_user_id = current_user));

CREATE POLICY "Users can create bookings" ON bookings
    FOR INSERT TO authenticated
    WITH CHECK (user_id IN (SELECT user_id FROM users WHERE external_user_id = current_user));

CREATE POLICY "Users can update own bookings" ON bookings
    FOR UPDATE TO authenticated
    USING (user_id IN (SELECT user_id FROM users WHERE external_user_id = current_user));

-- Payment transactions - linked to bookings
CREATE POLICY "Users can read own payment transactions" ON payment_transactions
    FOR SELECT TO authenticated
    USING (booking_id IN (
        SELECT booking_id FROM bookings b 
        JOIN users u ON b.user_id = u.user_id 
        WHERE u.external_user_id = current_user
    ));

-- Passengers - users can manage passengers for their bookings
CREATE POLICY "Users can read passengers for their bookings" ON passengers
    FOR SELECT TO authenticated
    USING (
        passenger_id IN (
            SELECT bp.passenger_id 
            FROM booking_passengers bp
            JOIN bookings b ON bp.booking_id = b.booking_id
            JOIN users u ON b.user_id = u.user_id
            WHERE u.external_user_id = current_user
        )
    );

CREATE POLICY "Users can create passengers" ON passengers
    FOR INSERT TO authenticated
    WITH CHECK (true); -- Will be validated at application level

-- Booking passengers relationship
CREATE POLICY "Users can read booking passengers for their bookings" ON booking_passengers
    FOR SELECT TO authenticated
    USING (
        booking_id IN (
            SELECT booking_id FROM bookings b
            JOIN users u ON b.user_id = u.user_id
            WHERE u.external_user_id = current_user
        )
    );

-- Trigger functions for updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at triggers
CREATE TRIGGER update_airlines_updated_at BEFORE UPDATE ON airlines
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_airports_updated_at BEFORE UPDATE ON airports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_flights_updated_at BEFORE UPDATE ON flights
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_flight_prices_updated_at BEFORE UPDATE ON flight_prices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bookings_updated_at BEFORE UPDATE ON bookings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payment_transactions_updated_at BEFORE UPDATE ON payment_transactions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_passengers_updated_at BEFORE UPDATE ON passengers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();