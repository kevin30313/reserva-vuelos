"""
Lambda function for flight search functionality
Optimized for Chilean flight search patterns
"""

import json
import boto3
import psycopg2
import os
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

class FlightSearchService:
    def __init__(self):
        self.db_secret_name = os.environ.get('DB_SECRET_NAME', 'vuelachile/db-password')
        self.region_name = os.environ.get('AWS_REGION', 'us-east-1')
        
        # Initialize AWS clients
        self.secrets_client = boto3.client('secretsmanager', region_name=self.region_name)
        self.elasticache_client = boto3.client('elasticache', region_name=self.region_name)
        
        # Cache configuration
        self.cache_ttl = 300  # 5 minutes cache for flight searches
        
        # Database connection
        self.db_connection = None
    
    def get_database_credentials(self) -> Dict[str, str]:
        """Retrieve database credentials from AWS Secrets Manager"""
        try:
            response = self.secrets_client.get_secret_value(SecretId=self.db_secret_name)
            return json.loads(response['SecretString'])
        except Exception as e:
            logger.error(f"Error retrieving database credentials: {str(e)}")
            raise
    
    def get_database_connection(self):
        """Establish database connection with connection pooling"""
        if self.db_connection is None or self.db_connection.closed:
            try:
                credentials = self.get_database_credentials()
                
                self.db_connection = psycopg2.connect(
                    host=credentials['host'],
                    port=credentials['port'],
                    database=credentials['dbname'],
                    user=credentials['username'],
                    password=credentials['password'],
                    sslmode='require',
                    connect_timeout=10,
                    application_name='vuelachile-flight-search'
                )
                
                # Set read-only for read replica if available
                if os.environ.get('USE_READ_REPLICA', 'false').lower() == 'true':
                    self.db_connection.set_session(readonly=True)
                    
            except Exception as e:
                logger.error(f"Database connection error: {str(e)}")
                raise
        
        return self.db_connection
    
    def search_flights(self, search_params: Dict[str, Any]) -> List[Dict[str, Any]]:
        """
        Search for flights based on parameters
        Optimized for Chilean routes and preferences
        """
        try:
            conn = self.get_database_connection()
            cursor = conn.cursor()
            
            # Build dynamic query based on search parameters
            base_query = """
                SELECT 
                    f.flight_id,
                    al.airline_name,
                    f.flight_number,
                    f.aircraft_type,
                    dep_airport.airport_code as departure_airport,
                    dep_airport.city_name as departure_city,
                    arr_airport.airport_code as arrival_airport,
                    arr_airport.city_name as arrival_city,
                    f.departure_time,
                    f.arrival_time,
                    f.flight_duration,
                    f.stops,
                    fp.price_economy,
                    fp.price_premium,
                    fp.price_business,
                    f.available_seats,
                    f.total_seats,
                    al.baggage_allowance,
                    al.cancellation_policy
                FROM flights f
                JOIN airlines al ON f.airline_id = al.airline_id
                JOIN airports dep_airport ON f.departure_airport_id = dep_airport.airport_id
                JOIN airports arr_airport ON f.arrival_airport_id = arr_airport.airport_id
                JOIN flight_prices fp ON f.flight_id = fp.flight_id
                WHERE 1=1
            """
            
            conditions = []
            params = []
            
            # Origin airport
            if search_params.get('from_airport'):
                conditions.append("dep_airport.airport_code = %s")
                params.append(search_params['from_airport'])
            
            # Destination airport
            if search_params.get('to_airport'):
                conditions.append("arr_airport.airport_code = %s")
                params.append(search_params['to_airport'])
            
            # Departure date
            if search_params.get('departure_date'):
                conditions.append("DATE(f.departure_time) = %s")
                params.append(search_params['departure_date'])
            
            # Return date for round trip
            if search_params.get('return_date') and search_params.get('trip_type') == 'roundtrip':
                # This would require a more complex query or separate search
                pass
            
            # Passenger count
            if search_params.get('passengers'):
                conditions.append("f.available_seats >= %s")
                params.append(search_params['passengers'])
            
            # Price range filter
            if search_params.get('max_price'):
                conditions.append("fp.price_economy <= %s")
                params.append(search_params['max_price'])
            
            # Direct flights only
            if search_params.get('direct_only'):
                conditions.append("f.stops = 0")
            
            # Airline filter
            if search_params.get('airline'):
                conditions.append("al.airline_code = %s")
                params.append(search_params['airline'])
            
            # Time preferences (morning, afternoon, evening)
            if search_params.get('time_preference'):
                time_pref = search_params['time_preference']
                if time_pref == 'morning':
                    conditions.append("EXTRACT(HOUR FROM f.departure_time) BETWEEN 6 AND 12")
                elif time_pref == 'afternoon':
                    conditions.append("EXTRACT(HOUR FROM f.departure_time) BETWEEN 12 AND 18")
                elif time_pref == 'evening':
                    conditions.append("EXTRACT(HOUR FROM f.departure_time) BETWEEN 18 AND 23")
            
            # Build final query
            if conditions:
                query = base_query + " AND " + " AND ".join(conditions)
            else:
                query = base_query
            
            # Add ordering - prioritize by price and departure time
            query += """
                ORDER BY 
                    fp.price_economy ASC,
                    f.departure_time ASC,
                    f.stops ASC
                LIMIT 50
            """
            
            cursor.execute(query, params)
            results = cursor.fetchall()
            
            # Format results
            flights = []
            for row in results:
                flight = {
                    'flight_id': row[0],
                    'airline': {
                        'name': row[1],
                        'baggage_allowance': row[17],
                        'cancellation_policy': row[18]
                    },
                    'flight_number': row[2],
                    'aircraft': row[3],
                    'departure': {
                        'airport': row[4],
                        'city': row[5],
                        'time': row[8].isoformat() if row[8] else None
                    },
                    'arrival': {
                        'airport': row[6],
                        'city': row[7],
                        'time': row[9].isoformat() if row[9] else None
                    },
                    'duration': str(row[10]) if row[10] else None,
                    'stops': row[11],
                    'pricing': {
                        'economy': float(row[12]) if row[12] else None,
                        'premium': float(row[13]) if row[13] else None,
                        'business': float(row[14]) if row[14] else None
                    },
                    'available_seats': row[15],
                    'total_seats': row[16],
                    'booking_class': self.determine_booking_class(row[15], row[16])
                }
                
                # Calculate Chilean tax (IVA 19%)
                if flight['pricing']['economy']:
                    flight['pricing']['economy_with_tax'] = flight['pricing']['economy'] * 1.19
                
                flights.append(flight)
            
            cursor.close()
            logger.info(f"Found {len(flights)} flights for search parameters")
            
            return flights
            
        except Exception as e:
            logger.error(f"Error searching flights: {str(e)}")
            raise
    
    def determine_booking_class(self, available_seats: int, total_seats: int) -> str:
        """Determine booking class based on availability"""
        if available_seats == 0:
            return 'sold_out'
        elif available_seats <= total_seats * 0.1:
            return 'limited'
        elif available_seats <= total_seats * 0.3:
            return 'moderate'
        else:
            return 'available'
    
    def get_popular_routes(self) -> List[Dict[str, Any]]:
        """Get popular Chilean flight routes"""
        try:
            conn = self.get_database_connection()
            cursor = conn.cursor()
            
            query = """
                SELECT 
                    dep.airport_code as from_airport,
                    dep.city_name as from_city,
                    arr.airport_code as to_airport,
                    arr.city_name as to_city,
                    COUNT(b.booking_id) as booking_count,
                    AVG(fp.price_economy) as avg_price
                FROM bookings b
                JOIN flights f ON b.flight_id = f.flight_id
                JOIN airports dep ON f.departure_airport_id = dep.airport_id
                JOIN airports arr ON f.arrival_airport_id = arr.airport_id
                JOIN flight_prices fp ON f.flight_id = fp.flight_id
                WHERE b.booking_date >= NOW() - INTERVAL '30 days'
                    AND b.booking_status != 'cancelled'
                GROUP BY dep.airport_code, dep.city_name, arr.airport_code, arr.city_name
                ORDER BY booking_count DESC
                LIMIT 10
            """
            
            cursor.execute(query)
            results = cursor.fetchall()
            
            routes = []
            for row in results:
                routes.append({
                    'from': {
                        'airport': row[0],
                        'city': row[1]
                    },
                    'to': {
                        'airport': row[2],
                        'city': row[3]
                    },
                    'popularity_score': row[4],
                    'average_price': float(row[5]) if row[5] else None
                })
            
            cursor.close()
            return routes
            
        except Exception as e:
            logger.error(f"Error getting popular routes: {str(e)}")
            return []
    
    def get_price_trends(self, from_airport: str, to_airport: str) -> Dict[str, Any]:
        """Get price trends for a specific route"""
        try:
            conn = self.get_database_connection()
            cursor = conn.cursor()
            
            query = """
                SELECT 
                    DATE(f.departure_time) as flight_date,
                    AVG(fp.price_economy) as avg_price,
                    MIN(fp.price_economy) as min_price,
                    MAX(fp.price_economy) as max_price,
                    COUNT(f.flight_id) as flight_count
                FROM flights f
                JOIN airports dep ON f.departure_airport_id = dep.airport_id
                JOIN airports arr ON f.arrival_airport_id = arr.airport_id
                JOIN flight_prices fp ON f.flight_id = fp.flight_id
                WHERE dep.airport_code = %s
                    AND arr.airport_code = %s
                    AND f.departure_time >= NOW()
                    AND f.departure_time <= NOW() + INTERVAL '90 days'
                GROUP BY DATE(f.departure_time)
                ORDER BY flight_date
            """
            
            cursor.execute(query, (from_airport, to_airport))
            results = cursor.fetchall()
            
            trends = {
                'route': {
                    'from': from_airport,
                    'to': to_airport
                },
                'price_data': []
            }
            
            for row in results:
                trends['price_data'].append({
                    'date': row[0].isoformat() if row[0] else None,
                    'average_price': float(row[1]) if row[1] else None,
                    'min_price': float(row[2]) if row[2] else None,
                    'max_price': float(row[3]) if row[3] else None,
                    'flight_count': row[4]
                })
            
            cursor.close()
            return trends
            
        except Exception as e:
            logger.error(f"Error getting price trends: {str(e)}")
            return {}

def lambda_handler(event, context):
    """
    Main Lambda handler for flight search
    """
    try:
        # Parse request
        if 'body' in event:
            request_body = json.loads(event['body']) if isinstance(event['body'], str) else event['body']
        else:
            request_body = event
        
        # Initialize service
        flight_service = FlightSearchService()
        
        # Determine action
        action = request_body.get('action', 'search')
        
        if action == 'search':
            search_params = request_body.get('search_params', {})
            results = flight_service.search_flights(search_params)
            
            response_data = {
                'flights': results,
                'search_params': search_params,
                'total_results': len(results)
            }
            
        elif action == 'popular_routes':
            results = flight_service.get_popular_routes()
            response_data = {
                'popular_routes': results
            }
            
        elif action == 'price_trends':
            from_airport = request_body.get('from_airport')
            to_airport = request_body.get('to_airport')
            
            if not from_airport or not to_airport:
                raise ValueError("from_airport and to_airport are required for price trends")
            
            results = flight_service.get_price_trends(from_airport, to_airport)
            response_data = results
            
        else:
            raise ValueError(f"Unknown action: {action}")
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'GET,POST,OPTIONS'
            },
            'body': json.dumps(response_data, default=str)
        }
        
    except Exception as e:
        logger.error(f"Lambda execution error: {str(e)}")
        
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.environ.get('DEBUG') == 'true' else 'An error occurred processing your request'
            })
        }