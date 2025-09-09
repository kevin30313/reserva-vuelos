/*
  # VuelaChile Database - Seed Data
  
  This migration populates the database with initial data for the Chilean flight booking platform.
  Includes Chilean airports, airlines, and sample flight data for testing.
  
  ## Data Inserted:
  
  1. **Chilean Airlines** - LATAM, Sky, JetSMART, and international carriers
  2. **Chilean Airports** - Major airports across Chile
  3. **Aircraft Types** - Common aircraft used in Chilean aviation
  4. **Sample Flights** - Representative flight schedules
  5. **Sample Pricing** - Realistic pricing for Chilean market
  
  ## Market Focus:
  
  - Domestic Chilean routes (Santiago, Valparaíso, Concepción, etc.)
  - International connections (Buenos Aires, Lima, São Paulo)
  - Chilean airline preferences and routing patterns
  - Local pricing in Chilean Pesos (CLP)
*/

-- Insert Chilean and International Airlines
INSERT INTO airlines (airline_code, airline_name, country_code, logo_url, website_url, baggage_allowance, cancellation_policy, is_active) VALUES
-- Chilean Airlines
('LA', 'LATAM Airlines Chile', 'CL', 'https://logos.skyscnr.com/images/airlines/favicon/LA.png', 'https://www.latam.com', 
 '{"carry_on": "8kg", "checked_economy": "23kg", "checked_premium": "32kg", "checked_business": "32kg"}',
 'Cancelación gratuita hasta 24 horas antes. Tarifa flexible permite cambios sin costo.', true),

('H2', 'Sky Airline', 'CL', 'https://logos.skyscnr.com/images/airlines/favicon/H2.png', 'https://www.skyairline.com',
 '{"carry_on": "8kg", "checked_economy": "23kg", "excess_fee": "15000_clp_per_kg"}',
 'Cancelación con costo según tarifa. Sky Flex permite cambios gratuitos.', true),

('JA', 'JetSMART', 'CL', 'https://logos.skyscnr.com/images/airlines/favicon/JA.png', 'https://jetsmart.com',
 '{"carry_on": "8kg", "checked_basic": "0kg", "checked_smart": "20kg", "checked_full": "25kg"}',
 'Tarifa SIMPLE no permite cambios. Tarifas SMART y FULL permiten cambios con costo.', true),

-- International Airlines serving Chile
('AR', 'Aerolíneas Argentinas', 'AR', 'https://logos.skyscnr.com/images/airlines/favicon/AR.png', 'https://www.aerolineas.com.ar',
 '{"carry_on": "8kg", "checked_economy": "23kg"}',
 'Política internacional de cancelación. Cambios permitidos según tarifa.', true),

('AV', 'Avianca', 'CO', 'https://logos.skyscnr.com/images/airlines/favicon/AV.png', 'https://www.avianca.com',
 '{"carry_on": "10kg", "checked_economy": "23kg"}',
 'Cancelación gratuita en tarifas flex. Cambios con costo en tarifas básicas.', true),

('LA', 'LATAM Airlines Peru', 'PE', 'https://logos.skyscnr.com/images/airlines/favicon/LA.png', 'https://www.latam.com',
 '{"carry_on": "8kg", "checked_economy": "23kg"}',
 'Misma política que LATAM Chile para vuelos internacionales.', true),

('G3', 'GOL Linhas Aéreas', 'BR', 'https://logos.skyscnr.com/images/airlines/favicon/G3.png', 'https://www.voegol.com.br',
 '{"carry_on": "10kg", "checked_economy": "23kg"}',
 'Política brasileña de cancelación. Cambios según tipo de tarifa.', true);

-- Insert Chilean Airports and Key International Destinations
INSERT INTO airports (airport_code, airport_name, city_name, region, country_code, timezone, coordinates, is_international, is_active) VALUES
-- Chilean Airports - Major Cities
('SCL', 'Aeropuerto Internacional Arturo Merino Benítez', 'Santiago', 'Metropolitana', 'CL', 'America/Santiago', point(-70.7869, -33.3930), true, true),
('LSC', 'Aeropuerto La Florida', 'La Serena', 'Coquimbo', 'CL', 'America/Santiago', point(-71.2192, -29.9161), false, true),
('CCP', 'Aeropuerto Internacional Carriel Sur', 'Concepción', 'Biobío', 'CL', 'America/Santiago', point(-73.0611, -36.7726), true, true),
('ZCO', 'Aeropuerto La Araucanía', 'Temuco', 'Araucanía', 'CL', 'America/Santiago', point(-72.6358, -38.7667), false, true),
('PMC', 'Aeropuerto El Tepual', 'Puerto Montt', 'Los Lagos', 'CL', 'America/Santiago', point(-73.0950, -41.4389), false, true),
('BBA', 'Aeropuerto Internacional Presidente Carlos Ibáñez del Campo', 'Punta Arenas', 'Magallanes', 'CL', 'America/Punta_Arenas', point(-70.8556, -53.0025), true, true),
('IPC', 'Aeropuerto Internacional Mataveri', 'Isla de Pascua', 'Valparaíso', 'CL', 'Pacific/Easter', point(-109.4219, -27.1648), true, true),
('CJC', 'Aeropuerto Internacional Chacalluta', 'Arica', 'Arica y Parinacota', 'CL', 'America/Santiago', point(-70.3386, -18.3486), true, true),
('IQQ', 'Aeropuerto Internacional Diego Aracena', 'Iquique', 'Tarapacá', 'CL', 'America/Santiago', point(-70.1811, -20.5356), true, true),
('ANF', 'Aeropuerto Internacional Andrés Sabella Gálvez', 'Antofagasta', 'Antofagasta', 'CL', 'America/Santiago', point(-70.4444, -23.4444), true, true),
('CPO', 'Aeropuerto Internacional Desierto de Atacama', 'Copiapó', 'Atacama', 'CL', 'America/Santiago', point(-70.7792, -27.2611), true, true),
('KNA', 'Aeropuerto Internacional Rodelillo', 'Viña del Mar/Valparaíso', 'Valparaíso', 'CL', 'America/Santiago', point(-71.5444, -32.9500), false, true),

-- Key International Destinations
('EZE', 'Aeropuerto Internacional Ezeiza', 'Buenos Aires', 'Buenos Aires', 'AR', 'America/Argentina/Buenos_Aires', point(-58.5358, -34.8222), true, true),
('LIM', 'Aeropuerto Internacional Jorge Chávez', 'Lima', 'Lima', 'PE', 'America/Lima', point(-77.1144, -12.0219), true, true),
('GRU', 'Aeropuerto Internacional de São Paulo-Guarulhos', 'São Paulo', 'São Paulo', 'BR', 'America/Sao_Paulo', point(-46.4697, -23.4356), true, true),
('BOG', 'Aeropuerto Internacional El Dorado', 'Bogotá', 'Cundinamarca', 'CO', 'America/Bogota', point(-74.1469, 4.7016), true, true),
('UIO', 'Aeropuerto Internacional Mariscal Sucre', 'Quito', 'Pichincha', 'EC', 'America/Guayaquil', point(-78.3578, -0.1292), true, true),
('MVD', 'Aeropuerto Internacional de Carrasco', 'Montevideo', 'Montevideo', 'UY', 'America/Montevideo', point(-56.0308, -34.8386), true, true);

-- Insert Aircraft Types commonly used in Chilean aviation
INSERT INTO aircraft_types (aircraft_code, manufacturer, model, capacity_economy, capacity_premium, capacity_business, range_km, cruise_speed_kmh) VALUES
-- Airbus family - popular with LATAM and Sky
('A319', 'Airbus', 'A319', 150, 0, 8, 6900, 828),
('A320', 'Airbus', 'A320', 174, 0, 12, 6150, 828),
('A321', 'Airbus', 'A321', 220, 0, 16, 7400, 828),
('A320N', 'Airbus', 'A320neo', 180, 0, 12, 6500, 828),

-- Boeing family
('B737', 'Boeing', '737-800', 189, 0, 0, 5765, 828),
('B738', 'Boeing', '737-800', 189, 16, 0, 5765, 828),
('B39M', 'Boeing', '737 MAX 9', 220, 16, 0, 6570, 839),
('B789', 'Boeing', '787-9 Dreamliner', 296, 28, 30, 14700, 903),

-- Regional aircraft
('AT72', 'ATR', 'ATR 72', 78, 0, 0, 1528, 510),
('DH8D', 'Bombardier', 'Dash 8 Q400', 78, 0, 0, 2040, 667),

-- Cargo/Charter
('B763', 'Boeing', '767-300', 269, 18, 30, 11070, 851);

-- Insert sample flights for the next 30 days
-- This creates a realistic flight schedule for major Chilean routes

-- Function to generate flight times
CREATE OR REPLACE FUNCTION generate_flights()
RETURNS void AS $$
DECLARE
    flight_date date;
    airline_record record;
    route_record record;
    aircraft_record record;
    base_price decimal(10,2);
    flight_num varchar(10);
BEGIN
    -- Define popular Chilean routes with realistic schedules
    FOR route_record IN (
        -- Santiago to other cities (most popular routes)
        SELECT 'SCL' as from_code, 'LSC' as to_code, 75000 as base_price, '1:30:00' as duration, 3 as daily_freq
        UNION ALL SELECT 'SCL', 'CCP', 85000, '1:45:00', 4
        UNION ALL SELECT 'SCL', 'ZCO', 95000, '1:20:00', 3
        UNION ALL SELECT 'SCL', 'PMC', 120000, '2:00:00', 2
        UNION ALL SELECT 'SCL', 'IQQ', 140000, '2:30:00', 2
        UNION ALL SELECT 'SCL', 'ANF', 130000, '2:15:00', 2
        UNION ALL SELECT 'SCL', 'CJC', 160000, '3:00:00', 1
        UNION ALL SELECT 'SCL', 'BBA', 280000, '3:30:00', 1
        
        -- Return flights
        UNION ALL SELECT 'LSC', 'SCL', 75000, '1:30:00', 3
        UNION ALL SELECT 'CCP', 'SCL', 85000, '1:45:00', 4
        UNION ALL SELECT 'ZCO', 'SCL', 95000, '1:20:00', 3
        UNION ALL SELECT 'PMC', 'SCL', 120000, '2:00:00', 2
        UNION ALL SELECT 'IQQ', 'SCL', 140000, '2:30:00', 2
        UNION ALL SELECT 'ANF', 'SCL', 130000, '2:15:00', 2
        UNION ALL SELECT 'CJC', 'SCL', 160000, '3:00:00', 1
        UNION ALL SELECT 'BBA', 'SCL', 280000, '3:30:00', 1
        
        -- International routes from Santiago
        UNION ALL SELECT 'SCL', 'EZE', 180000, '2:15:00', 2
        UNION ALL SELECT 'SCL', 'LIM', 220000, '3:20:00', 2
        UNION ALL SELECT 'SCL', 'GRU', 350000, '3:45:00', 1
        UNION ALL SELECT 'SCL', 'BOG', 380000, '5:30:00', 1
        
        -- Return international
        UNION ALL SELECT 'EZE', 'SCL', 180000, '2:15:00', 2
        UNION ALL SELECT 'LIM', 'SCL', 220000, '3:20:00', 2
        UNION ALL SELECT 'GRU', 'SCL', 350000, '3:45:00', 1
        UNION ALL SELECT 'BOG', 'SCL', 380000, '5:30:00', 1
        
        -- Some regional connections
        UNION ALL SELECT 'CCP', 'ZCO', 65000, '1:00:00', 1
        UNION ALL SELECT 'ZCO', 'CCP', 65000, '1:00:00', 1
        UNION ALL SELECT 'CCP', 'PMC', 75000, '1:15:00', 1
        UNION ALL SELECT 'PMC', 'CCP', 75000, '1:15:00', 1
    ) LOOP
        
        -- Generate flights for next 30 days
        FOR i IN 0..29 LOOP
            flight_date := CURRENT_DATE + i;
            
            -- Generate multiple flights per day based on frequency
            FOR j IN 1..route_record.daily_freq LOOP
                
                -- Cycle through airlines for variety
                FOR airline_record IN (
                    SELECT * FROM airlines 
                    WHERE is_active = true 
                    AND country_code = 'CL'
                    ORDER BY airline_code
                    LIMIT 3
                ) LOOP
                    
                    -- Get appropriate aircraft
                    SELECT * INTO aircraft_record FROM aircraft_types 
                    WHERE aircraft_code IN ('A320', 'A319', 'B737', 'A320N')
                    ORDER BY random() LIMIT 1;
                    
                    -- Generate flight number
                    flight_num := airline_record.airline_code || ' ' || 
                                 (1000 + (i * 10) + j + ascii(airline_record.airline_code))::text;
                    
                    -- Calculate departure time (spread throughout day)
                    DECLARE
                        departure_time timestamptz;
                        arrival_time timestamptz;
                        dep_airport_id uuid;
                        arr_airport_id uuid;
                        total_seats integer;
                        available_seats integer;
                    BEGIN
                        -- Morning, afternoon, or evening flights
                        departure_time := flight_date::timestamptz + 
                                        interval '6 hours' + 
                                        interval '4 hours' * (j - 1) +
                                        interval '30 minutes' * random();
                        
                        arrival_time := departure_time + route_record.duration::interval;
                        
                        -- Get airport IDs
                        SELECT airport_id INTO dep_airport_id FROM airports WHERE airport_code = route_record.from_code;
                        SELECT airport_id INTO arr_airport_id FROM airports WHERE airport_code = route_record.to_code;
                        
                        -- Set capacity
                        total_seats := aircraft_record.capacity_economy + 
                                      COALESCE(aircraft_record.capacity_premium, 0) + 
                                      COALESCE(aircraft_record.capacity_business, 0);
                        available_seats := total_seats - floor(random() * total_seats * 0.3); -- 0-30% sold
                        
                        -- Insert flight
                        INSERT INTO flights (
                            airline_id, flight_number, 
                            departure_airport_id, arrival_airport_id,
                            aircraft_type_id, departure_time, arrival_time,
                            total_seats, available_seats, status
                        ) VALUES (
                            airline_record.airline_id, flight_num,
                            dep_airport_id, arr_airport_id,
                            aircraft_record.aircraft_id, departure_time, arrival_time,
                            total_seats, available_seats, 'scheduled'
                        );
                        
                        -- Insert pricing
                        base_price := route_record.base_price + (route_record.base_price * random() * 0.3 - route_record.base_price * 0.15); -- ±15% variation
                        
                        INSERT INTO flight_prices (
                            flight_id, price_economy, price_premium, price_business,
                            base_price, currency_code, includes_tax
                        ) VALUES (
                            currval(pg_get_serial_sequence('flights', 'flight_id')),
                            base_price,
                            base_price * 1.4, -- Premium 40% more
                            base_price * 2.2, -- Business 120% more
                            base_price / 1.19, -- Base price without IVA
                            'CLP', false
                        );
                    END;
                    
                    -- Only create one flight per airline per route per day (adjust as needed)
                    EXIT;
                END LOOP;
            END LOOP;
        END LOOP;
    END LOOP;
    
    RAISE NOTICE 'Generated sample flights successfully';
END;
$$ LANGUAGE plpgsql;

-- Execute the function to generate flights
SELECT generate_flights();

-- Drop the temporary function
DROP FUNCTION generate_flights();

-- Insert sample user for testing (will be synced from on-premise)
INSERT INTO users (
    external_user_id, email, first_name, last_name, 
    phone, date_of_birth, nationality, document_type, document_number,
    preferred_language, marketing_consent, is_active
) VALUES 
('test_user_001', 'test@vuelachile.cl', 'Juan Carlos', 'González',
 '+56912345678', '1985-03-15', 'CL', 'rut', '12.345.678-9',
 'es', true, true),
 
('test_user_002', 'maria@vuelachile.cl', 'María Elena', 'Rodriguez', 
 '+56987654321', '1990-07-22', 'CL', 'rut', '98.765.432-1',
 'es', false, true);

-- Create some sample bookings for testing
DO $$
DECLARE
    test_flight_id uuid;
    test_user_id uuid;
    booking_ref varchar(20);
BEGIN
    -- Get a test flight
    SELECT flight_id INTO test_flight_id FROM flights LIMIT 1;
    SELECT user_id INTO test_user_id FROM users WHERE email = 'test@vuelachile.cl';
    
    IF test_flight_id IS NOT NULL AND test_user_id IS NOT NULL THEN
        booking_ref := 'VC' || to_char(now(), 'YYMMDD') || '001';
        
        INSERT INTO bookings (
            booking_reference, user_id, flight_id,
            booking_status, payment_status, passenger_count,
            total_amount, booking_class, booking_source
        ) VALUES (
            booking_ref, test_user_id, test_flight_id,
            'confirmed', 'paid', 1,
            89000.00, 'economy', 'web'
        );
        
        RAISE NOTICE 'Created test booking: %', booking_ref;
    END IF;
END $$;

-- Update statistics for better query planning
ANALYZE airlines;
ANALYZE airports;
ANALYZE aircraft_types;
ANALYZE flights;
ANALYZE flight_prices;
ANALYZE users;
ANALYZE bookings;

-- Create view for popular routes analysis
CREATE OR REPLACE VIEW popular_routes AS
SELECT 
    da.city_name as departure_city,
    da.airport_code as departure_airport,
    aa.city_name as arrival_city,
    aa.airport_code as arrival_airport,
    COUNT(f.flight_id) as flight_count,
    AVG(fp.price_economy) as avg_price,
    MIN(fp.price_economy) as min_price,
    MAX(fp.price_economy) as max_price
FROM flights f
JOIN airports da ON f.departure_airport_id = da.airport_id
JOIN airports aa ON f.arrival_airport_id = aa.airport_id
JOIN flight_prices fp ON f.flight_id = fp.flight_id
WHERE f.departure_time >= CURRENT_DATE
GROUP BY da.city_name, da.airport_code, aa.city_name, aa.airport_code
ORDER BY flight_count DESC;

-- Create view for flight search optimization
CREATE OR REPLACE VIEW flight_search_view AS
SELECT 
    f.flight_id,
    al.airline_name,
    al.airline_code,
    f.flight_number,
    act.manufacturer || ' ' || act.model as aircraft,
    da.airport_code as departure_airport,
    da.city_name as departure_city,
    aa.airport_code as arrival_airport,
    aa.city_name as arrival_city,
    f.departure_time,
    f.arrival_time,
    f.flight_duration,
    f.stops,
    fp.price_economy,
    fp.price_premium,
    fp.price_business,
    f.available_seats,
    f.total_seats,
    f.status,
    al.baggage_allowance,
    CASE 
        WHEN f.available_seats = 0 THEN 'sold_out'
        WHEN f.available_seats <= f.total_seats * 0.1 THEN 'limited'
        WHEN f.available_seats <= f.total_seats * 0.3 THEN 'moderate'
        ELSE 'available'
    END as booking_class
FROM flights f
JOIN airlines al ON f.airline_id = al.airline_id
JOIN airports da ON f.departure_airport_id = da.airport_id
JOIN airports aa ON f.arrival_airport_id = aa.airport_id
JOIN aircraft_types act ON f.aircraft_type_id = act.aircraft_id
JOIN flight_prices fp ON f.flight_id = fp.flight_id
WHERE f.is_active = true 
    AND al.is_active = true
    AND f.departure_time > now();

-- Performance optimization: Create materialized view for popular searches
CREATE MATERIALIZED VIEW flight_search_cache AS
SELECT * FROM flight_search_view
WHERE departure_time <= CURRENT_DATE + interval '90 days';

-- Create index on materialized view
CREATE INDEX idx_flight_search_cache_route ON flight_search_cache(departure_airport, arrival_airport, departure_time);
CREATE INDEX idx_flight_search_cache_price ON flight_search_cache(price_economy);

-- Refresh materialized view (should be done periodically)
REFRESH MATERIALIZED VIEW flight_search_cache;

-- Grant permissions for application user (to be created)
-- CREATE USER vuelachile_app WITH PASSWORD 'secure_password';
-- GRANT CONNECT ON DATABASE vuelachile TO vuelachile_app;
-- GRANT USAGE ON SCHEMA public TO vuelachile_app;
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO vuelachile_app;
-- GRANT INSERT, UPDATE ON bookings, payment_transactions, passengers, booking_passengers TO vuelachile_app;

COMMIT;