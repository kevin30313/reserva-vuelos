"""
Lambda function for Transbank payment processing
Integrates with Chilean payment system
"""

import json
import boto3
import requests
import hmac
import hashlib
import base64
import uuid
from datetime import datetime, timedelta
import logging
import os
from typing import Dict, Any, Optional

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

class TransbankPaymentService:
    def __init__(self):
        self.environment = os.environ.get('TRANSBANK_ENVIRONMENT', 'integration')
        self.secrets_client = boto3.client('secretsmanager')
        
        # Transbank URLs
        if self.environment == 'production':
            self.base_url = 'https://webpay3g.transbank.cl'
        else:
            self.base_url = 'https://webpay3gint.transbank.cl'
        
        # Get credentials
        self.credentials = self._get_transbank_credentials()
        
        # Database connection for order management
        self.db_client = boto3.client('rds-data')
        self.db_cluster_arn = os.environ.get('DB_CLUSTER_ARN')
        self.db_secret_arn = os.environ.get('DB_SECRET_ARN')
        
    def _get_transbank_credentials(self) -> Dict[str, str]:
        """Get Transbank credentials from AWS Secrets Manager"""
        try:
            secret_name = f"vuelachile/transbank-{self.environment}"
            response = self.secrets_client.get_secret_value(SecretId=secret_name)
            return json.loads(response['SecretString'])
        except Exception as e:
            logger.error(f"Error retrieving Transbank credentials: {str(e)}")
            # Fallback to default test credentials for integration
            if self.environment == 'integration':
                return {
                    'commerce_code': '597055555532',
                    'api_key': '579B532A7440BB0C9079DED94D31EA1615BACEB56610332264630D42D0A36B1C'
                }
            raise
    
    def create_payment_transaction(self, payment_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Create a new payment transaction with Transbank
        """
        try:
            # Generate unique buy order
            buy_order = f"VC-{datetime.now().strftime('%Y%m%d')}-{uuid.uuid4().hex[:8].upper()}"
            
            # Calculate total amount (including Chilean IVA 19%)
            base_amount = payment_data['amount']
            tax_amount = base_amount * 0.19
            total_amount = int(base_amount + tax_amount)  # Transbank requires integers
            
            # Prepare transaction data
            transaction_data = {
                'buy_order': buy_order,
                'session_id': payment_data.get('session_id', uuid.uuid4().hex),
                'amount': total_amount,
                'return_url': payment_data.get('return_url', 'https://vuelachile.cl/payment/return')
            }
            
            # Create transaction with Transbank
            response = self._call_transbank_api('/rswebpaytransaction/api/webpay/v1.2/transactions', 'POST', transaction_data)
            
            if response.get('url') and response.get('token'):
                # Store transaction in database
                self._store_transaction({
                    'buy_order': buy_order,
                    'token': response['token'],
                    'amount': total_amount,
                    'base_amount': base_amount,
                    'tax_amount': tax_amount,
                    'flight_id': payment_data.get('flight_id'),
                    'user_id': payment_data.get('user_id'),
                    'passenger_count': payment_data.get('passenger_count', 1),
                    'status': 'pending',
                    'created_at': datetime.now().isoformat()
                })
                
                return {
                    'success': True,
                    'transaction_id': buy_order,
                    'payment_url': response['url'],
                    'token': response['token'],
                    'amount': total_amount,
                    'currency': 'CLP'
                }
            else:
                raise Exception(f"Invalid response from Transbank: {response}")
                
        except Exception as e:
            logger.error(f"Error creating Transbank transaction: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def confirm_payment_transaction(self, token: str) -> Dict[str, Any]:
        """
        Confirm a payment transaction with Transbank
        """
        try:
            # Get transaction status from Transbank
            response = self._call_transbank_api(f'/rswebpaytransaction/api/webpay/v1.2/transactions/{token}', 'PUT')
            
            if response:
                # Parse response
                vci = response.get('vci')
                amount = response.get('amount')
                status = response.get('status')
                buy_order = response.get('buy_order')
                session_id = response.get('session_id')
                card_detail = response.get('card_detail', {})
                accounting_date = response.get('accounting_date')
                transaction_date = response.get('transaction_date')
                authorization_code = response.get('authorization_code')
                payment_type_code = response.get('payment_type_code')
                response_code = response.get('response_code')
                installments_number = response.get('installments_number')
                
                # Determine payment status
                if status == 'AUTHORIZED' and response_code == 0:
                    payment_status = 'approved'
                elif status == 'FAILED':
                    payment_status = 'rejected'
                else:
                    payment_status = 'pending'
                
                # Update transaction in database
                self._update_transaction(buy_order, {
                    'status': payment_status,
                    'authorization_code': authorization_code,
                    'response_code': response_code,
                    'transaction_date': transaction_date,
                    'accounting_date': accounting_date,
                    'card_number': card_detail.get('card_number'),
                    'installments': installments_number,
                    'payment_type': self._get_payment_type_description(payment_type_code),
                    'confirmed_at': datetime.now().isoformat()
                })
                
                # If payment approved, process booking
                if payment_status == 'approved':
                    self._process_successful_booking(buy_order)
                
                return {
                    'success': True,
                    'transaction_id': buy_order,
                    'status': payment_status,
                    'amount': amount,
                    'authorization_code': authorization_code,
                    'card_info': {
                        'last_four': card_detail.get('card_number', '')[-4:] if card_detail.get('card_number') else None,
                        'card_type': self._get_payment_type_description(payment_type_code)
                    },
                    'transaction_date': transaction_date,
                    'installments': installments_number
                }
            else:
                raise Exception("No response from Transbank confirmation")
                
        except Exception as e:
            logger.error(f"Error confirming Transbank transaction: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def _call_transbank_api(self, endpoint: str, method: str, data: Optional[Dict] = None) -> Dict[str, Any]:
        """Make API call to Transbank"""
        try:
            url = f"{self.base_url}{endpoint}"
            headers = {
                'Tbk-Api-Key-Id': self.credentials['commerce_code'],
                'Tbk-Api-Key-Secret': self.credentials['api_key'],
                'Content-Type': 'application/json'
            }
            
            if method == 'POST':
                response = requests.post(url, headers=headers, json=data, timeout=30)
            elif method == 'PUT':
                response = requests.put(url, headers=headers, json=data, timeout=30)
            elif method == 'GET':
                response = requests.get(url, headers=headers, timeout=30)
            else:
                raise ValueError(f"Unsupported HTTP method: {method}")
            
            response.raise_for_status()
            return response.json()
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Transbank API request failed: {str(e)}")
            raise
    
    def _store_transaction(self, transaction_data: Dict[str, Any]):
        """Store transaction data in database"""
        try:
            sql = """
                INSERT INTO payment_transactions (
                    buy_order, token, amount, base_amount, tax_amount,
                    flight_id, user_id, passenger_count, status,
                    payment_method, created_at
                ) VALUES (
                    :buy_order, :token, :amount, :base_amount, :tax_amount,
                    :flight_id, :user_id, :passenger_count, :status,
                    'transbank', :created_at
                )
            """
            
            parameters = [
                {'name': key, 'value': {'stringValue': str(value)} if value is not None else {'isNull': True}}
                for key, value in transaction_data.items()
            ]
            
            self.db_client.execute_statement(
                resourceArn=self.db_cluster_arn,
                secretArn=self.db_secret_arn,
                database='vuelachile',
                sql=sql,
                parameters=parameters
            )
            
        except Exception as e:
            logger.error(f"Error storing transaction: {str(e)}")
            raise
    
    def _update_transaction(self, buy_order: str, update_data: Dict[str, Any]):
        """Update transaction status"""
        try:
            set_clauses = []
            parameters = [{'name': 'buy_order', 'value': {'stringValue': buy_order}}]
            
            for key, value in update_data.items():
                set_clauses.append(f"{key} = :{key}")
                parameters.append({
                    'name': key,
                    'value': {'stringValue': str(value)} if value is not None else {'isNull': True}
                })
            
            sql = f"UPDATE payment_transactions SET {', '.join(set_clauses)} WHERE buy_order = :buy_order"
            
            self.db_client.execute_statement(
                resourceArn=self.db_cluster_arn,
                secretArn=self.db_secret_arn,
                database='vuelachile',
                sql=sql,
                parameters=parameters
            )
            
        except Exception as e:
            logger.error(f"Error updating transaction: {str(e)}")
            raise
    
    def _process_successful_booking(self, buy_order: str):
        """Process successful booking after payment confirmation"""
        try:
            # Get transaction details
            sql_get = "SELECT * FROM payment_transactions WHERE buy_order = :buy_order"
            
            response = self.db_client.execute_statement(
                resourceArn=self.db_cluster_arn,
                secretArn=self.db_secret_arn,
                database='vuelachile',
                sql=sql_get,
                parameters=[{'name': 'buy_order', 'value': {'stringValue': buy_order}}]
            )
            
            if response['records']:
                transaction = response['records'][0]
                
                # Create booking record
                booking_id = f"BK-{datetime.now().strftime('%Y%m%d')}-{uuid.uuid4().hex[:8].upper()}"
                
                sql_booking = """
                    INSERT INTO bookings (
                        booking_id, flight_id, user_id, passenger_count,
                        total_amount, payment_status, booking_status,
                        payment_method, transaction_reference,
                        booking_date, created_at
                    ) VALUES (
                        :booking_id, :flight_id, :user_id, :passenger_count,
                        :total_amount, 'paid', 'confirmed',
                        'transbank', :buy_order,
                        NOW(), NOW()
                    )
                """
                
                booking_params = [
                    {'name': 'booking_id', 'value': {'stringValue': booking_id}},
                    {'name': 'flight_id', 'value': {'stringValue': str(transaction[4]['stringValue'])}},
                    {'name': 'user_id', 'value': {'stringValue': str(transaction[5]['stringValue'])}},
                    {'name': 'passenger_count', 'value': {'longValue': int(transaction[6]['stringValue'])}},
                    {'name': 'total_amount', 'value': {'stringValue': str(transaction[2]['stringValue'])}},
                    {'name': 'buy_order', 'value': {'stringValue': buy_order}}
                ]
                
                self.db_client.execute_statement(
                    resourceArn=self.db_cluster_arn,
                    secretArn=self.db_secret_arn,
                    database='vuelachile',
                    sql=sql_booking,
                    parameters=booking_params
                )
                
                # Send confirmation email (integrate with SES)
                self._send_booking_confirmation(booking_id)
                
        except Exception as e:
            logger.error(f"Error processing successful booking: {str(e)}")
            # Don't raise here to avoid blocking payment confirmation
    
    def _send_booking_confirmation(self, booking_id: str):
        """Send booking confirmation email"""
        try:
            # This would integrate with Amazon SES
            # For now, just log the action
            logger.info(f"Booking confirmation would be sent for: {booking_id}")
            
            # TODO: Implement SES email sending
            # ses_client = boto3.client('ses')
            # ses_client.send_email(...)
            
        except Exception as e:
            logger.error(f"Error sending booking confirmation: {str(e)}")
    
    def _get_payment_type_description(self, payment_type_code: str) -> str:
        """Get payment type description from code"""
        payment_types = {
            'VD': 'Tarjeta de Débito',
            'VN': 'Tarjeta de Crédito',
            'VC': 'Tarjeta de Crédito',
            'SI': 'Sin Interés',
            'S2': '2 cuotas sin interés',
            'S3': '3 cuotas sin interés',
            'N2': '2 cuotas con interés',
            'N3': '3 cuotas con interés',
            'N4': '4 cuotas con interés'
        }
        return payment_types.get(payment_type_code, f'Tipo {payment_type_code}')

def lambda_handler(event, context):
    """
    Lambda handler for Transbank payment processing
    """
    try:
        # Parse request
        if 'body' in event:
            request_body = json.loads(event['body']) if isinstance(event['body'], str) else event['body']
        else:
            request_body = event
        
        # Initialize payment service
        payment_service = TransbankPaymentService()
        
        # Determine action
        action = request_body.get('action', 'create')
        
        if action == 'create':
            # Create new payment transaction
            payment_data = request_body.get('payment_data', {})
            result = payment_service.create_payment_transaction(payment_data)
            
        elif action == 'confirm':
            # Confirm payment transaction
            token = request_body.get('token')
            if not token:
                raise ValueError("Token is required for payment confirmation")
            
            result = payment_service.confirm_payment_transaction(token)
            
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
            'body': json.dumps(result, default=str)
        }
        
    except Exception as e:
        logger.error(f"Payment processing error: {str(e)}")
        
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'success': False,
                'error': str(e) if os.environ.get('DEBUG') == 'true' else 'Payment processing failed'
            })
        }