# Donjo Backend Microservices

A modular, high-performance, and memory-efficient microservices backend powered by **Go**, **Podman**, **SQLite**, **RabbitMQ**, and **Elasticsearch**.

---

## 🚀 Microservices Overview

| Microservice | Path | Port | Container Name | Description |
|---|---|---|---|---|
| **API Gateway** | [`donjo_api_gateway`](file:///home/jkolaka/donjo/backend/donjo_api_gateway) | `8087` | `donjo_gateway` | Stateless reverse proxy, aggregated health, rate limiter |
| **Auth / Core** | [`donjo_backend`](file:///home/jkolaka/donjo/backend/donjo_backend) | `8080` | `donjo_backend` | Auth, user profiles, 2FA, sessions, avatar uploads |
| **Events** | [`donjo_event`](file:///home/jkolaka/donjo/backend/donjo_event) | `8081` | `donjo_event` | Event creation, schedule, venue management |
| **Bookings** | [`donjo_booking`](file:///home/jkolaka/donjo/backend/donjo_booking) | `8082` | `donjo_booking` | Ticket instances, QR check-ins, waitlists |
| **Payments** | [`donjo_payment`](file:///home/jkolaka/donjo/backend/donjo_payment) | `8083` | `donjo_payment` | Transactions, wallets, escrow management |
| **Search** | [`donjo_search`](file:///home/jkolaka/donjo/backend/donjo_search) | `8084` | `donjo_search` | Elasticsearch integration and fast query engine |
| **ML Engine** | [`donjo_ml`](file:///home/jkolaka/donjo/backend/donjo_ml) | `8085` | `donjo_ml` | Recommendation algorithms and similarity matching |
| **Notifications** | [`donjo_notifications`](file:///home/jkolaka/donjo/backend/donjo_notifications) | `8086` | `donjo_notifications` | Push notifications, in-app feed, notification templates |
| **Infra** | [`infra`](file:///home/jkolaka/donjo/backend/infra) | `5672`, `9200` | `rabbitmq`, `elasticsearch` | RabbitMQ event bus & Elasticsearch search index |

---

## 🛠️ Podman Commands

### Manage the Entire Fleet

From the [`backend/`](file:///home/jkolaka/donjo/backend) folder:

```bash
# Start all 8 microservices and shared infrastructure
make up

# View running containers, status, and ports
make ps

# Tail all container logs
make logs

# Stop all containers
make down

# Clean containers and persistent volumes
make clean
```

### Manage Individual Microservices

Each microservice is an independent containerized unit:

```bash
# Manage Auth Service
make up-auth
make down-auth
make logs-auth

# Manage Event Service
make up-event
make down-event
make logs-event

# Or run directly from any service directory
cd donjo_booking
make podman-up
make podman-logs
make podman-down
```

### Helper Script

Alternatively, you can use the interactive CLI helper:

```bash
./podman-dev.sh up
./podman-dev.sh status
./podman-dev.sh down
```
