# Donjo Backend - Master Podman Makefile
# Manages all microservices and shared infrastructure with Podman

COMPOSE = podman compose

all: help

help:
	@echo "=================================================================="
	@echo " Donjo Backend - Podman Orchestration Management"
	@echo "=================================================================="
	@echo " Fleet Commands:"
	@echo "   make up           - Start shared infra and all 8 microservices"
	@echo "   make down         - Stop all backend containers"
	@echo "   make build        - Build all microservice Podman images"
	@echo "   make ps           - View running containers and status"
	@echo "   make logs         - Stream logs from all backend containers"
	@echo "   make clean        - Stop containers and remove volumes"
	@echo ""
	@echo " Infrastructure Commands (RabbitMQ + Elasticsearch):"
	@echo "   make infra-up     - Start RabbitMQ (5672/15672) & Elasticsearch (9200)"
	@echo "   make infra-down   - Stop shared infrastructure"
	@echo "   make infra-logs   - Stream infrastructure logs"
	@echo ""
	@echo " Individual Microservice Commands:"
	@echo "   make up-gateway        make down-gateway        make logs-gateway"
	@echo "   make up-auth           make down-auth           make logs-auth"
	@echo "   make up-event          make down-event          make logs-event"
	@echo "   make up-booking        make down-booking        make logs-booking"
	@echo "   make up-payment        make down-payment        make logs-payment"
	@echo "   make up-search         make down-search         make logs-search"
	@echo "   make up-ml             make down-ml             make logs-ml"
	@echo "   make up-notifications  make down-notifications  make logs-notifications"
	@echo "=================================================================="

# Ensure podman user socket & shared network exist
podman-init:
	@if [ ! -S "/run/user/$$(id -u)/podman/podman.sock" ]; then \
		systemctl --user start podman.socket 2>/dev/null || true; \
	fi
	@podman network exists donjo-net 2>/dev/null || (podman network create donjo-net >/dev/null && echo "Created podman network: donjo-net")

# -----------------------------------------------------------------------------
# Fleet Orchestration
# -----------------------------------------------------------------------------
up: podman-init
	@echo "Starting entire Donjo fleet with Podman..."
	@$(COMPOSE) up -d --build

down: podman-init
	@echo "Stopping Donjo fleet..."
	@$(COMPOSE) down

build: podman-init
	@echo "Building all container images..."
	@$(COMPOSE) build

ps:
	@podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Size}}"

status: ps

logs:
	@$(COMPOSE) logs -f

clean: podman-init
	@echo "Cleaning up containers and volumes..."
	@$(COMPOSE) down -v

# -----------------------------------------------------------------------------
# Infrastructure (RabbitMQ & Elasticsearch)
# -----------------------------------------------------------------------------
infra-up: podman-init
	@cd infra && make up

infra-down: podman-init
	@cd infra && make down

infra-logs:
	@cd infra && make logs

# -----------------------------------------------------------------------------
# Individual Microservice Targets
# -----------------------------------------------------------------------------
# 1. API Gateway (:8087)
up-gateway: podman-init
	@cd donjo_api_gateway && make podman-up
down-gateway: podman-init
	@cd donjo_api_gateway && make podman-down
logs-gateway:
	@cd donjo_api_gateway && make podman-logs

# 2. Auth Service (:8080)
up-auth: podman-init
	@cd donjo_backend && make podman-up
down-auth: podman-init
	@cd donjo_backend && make podman-down
logs-auth:
	@cd donjo_backend && make podman-logs

# 3. Event Service (:8081)
up-event: podman-init
	@cd donjo_event && make podman-up
down-event: podman-init
	@cd donjo_event && make podman-down
logs-event:
	@cd donjo_event && make podman-logs

# 4. Booking Service (:8082)
up-booking: podman-init
	@cd donjo_booking && make podman-up
down-booking: podman-init
	@cd donjo_booking && make podman-down
logs-booking:
	@cd donjo_booking && make podman-logs

# 5. Payment Service (:8083)
up-payment: podman-init
	@cd donjo_payment && make podman-up
down-payment: podman-init
	@cd donjo_payment && make podman-down
logs-payment:
	@cd donjo_payment && make podman-logs

# 6. Search Service (:8084)
up-search: podman-init
	@cd donjo_search && make podman-up
down-search:
	@cd donjo_search && make podman-down
logs-search:
	@cd donjo_search && make podman-logs

# 7. ML Service (:8085)
up-ml: podman-init
	@cd donjo_ml && make podman-up
down-ml:
	@cd donjo_ml && make podman-down
logs-ml:
	@cd donjo_ml && make podman-logs

# 8. Notifications Service (:8086)
up-notifications: podman-init
	@cd donjo_notifications && make podman-up
down-notifications:
	@cd donjo_notifications && make podman-down
logs-notifications:
	@cd donjo_notifications && make podman-logs

# Aliases
podman-up: up
podman-down: down
podman-build: build

.PHONY: all help podman-init up down build ps status logs clean \
        infra-up infra-down infra-logs \
        up-gateway down-gateway logs-gateway \
        up-auth down-auth logs-auth \
        up-event down-event logs-event \
        up-booking down-booking logs-booking \
        up-payment down-payment logs-payment \
        up-search down-search logs-search \
        up-ml down-ml logs-ml \
        up-notifications down-notifications logs-notifications \
        podman-up podman-down podman-build
