# Sistema de Reservas de Vuelos Chile - VuelaChile

## 🛫 Descripción

VuelaChile es una plataforma moderna de reservas de vuelos diseñada específicamente para el mercado chileno, con arquitectura híbrida que combina seguridad on-premise para autenticación y escalabilidad en la nube para servicios principales.

## 🏗️ Arquitectura Híbrida

### Frontend (React + TypeScript)
- **Framework**: Vite + React 18 con TypeScript
- **Estilos**: Tailwind CSS con tema personalizado
- **Iconos**: Lucide React
- **Responsivo**: Mobile-first design con breakpoints optimizados

### Backend Híbrido

#### Componente On-Premise
- **Autenticación**: Servidor dedicado para login/registro de usuarios
- **Datos sensibles**: PII y credenciales almacenados localmente
- **Tecnología sugerida**: Java Spring Boot o Python FastAPI

#### Componente Cloud (AWS)
- **API Gateway**: Punto de entrada unificado
- **Lambda Functions**: Microservicios para búsqueda, reservas, pagos
- **ECS/Fargate**: Para servicios que requieren mayor compute
- **RDS Multi-AZ**: PostgreSQL con réplicas de lectura

## 💳 Integración de Pagos Chilenos

### Métodos Soportados
- **Transbank**: Tarjetas de débito y crédito nacionales
- **Khipu**: Transferencias bancarias instantáneas
- **Flow**: Alternativa para e-commerce
- **Mercado Pago**: Wallets digitales

### Implementación
```javascript
// Configuración para pagos chilenos
const paymentConfig = {
  transbank: {
    environment: 'production', // o 'integration'
    commerceCode: process.env.TRANSBANK_CC,
    apiKey: process.env.TRANSBANK_API_KEY
  },
  khipu: {
    receiverId: process.env.KHIPU_RECEIVER_ID,
    secret: process.env.KHIPU_SECRET
  }
}
```

## 🗄️ Arquitectura de Base de Datos

### Amazon RDS Multi-AZ Setup
```yaml
Primary Database:
- Engine: PostgreSQL 15
- Instance: db.t3.medium (económico pero escalable)
- Multi-AZ: true
- Storage: gp3 con auto-scaling
- Backup: 7 días de retención

Read Replicas:
- Región primaria: us-east-1 (Virginia)
- Región secundaria: us-west-2 (Oregon)
- Cross-region replication para DR

Tablas Principales:
- users (on-premise sync)
- flights
- bookings
- payments
- airports
- airlines
```

### Optimizaciones
- Índices compuestos para búsquedas frecuentes
- Particionamiento por fechas en tablas de vuelos
- Connection pooling con RDS Proxy
- Query caching con ElastiCache

## 🚀 Infraestructura Terraform