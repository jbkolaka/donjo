#!/usr/bin/env bash
# ==============================================================================
# Donjo Backend - Podman Management CLI
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

NETWORK_NAME="donjo-net"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

ensure_socket() {
    local socket_path="/run/user/$(id -u)/podman/podman.sock"
    if [ ! -S "${socket_path}" ]; then
        log_info "Activating rootless Podman user socket..."
        systemctl --user start podman.socket 2>/dev/null || true
    fi
}

ensure_network() {
    if ! podman network exists "${NETWORK_NAME}" 2>/dev/null; then
        log_info "Creating Podman network '${NETWORK_NAME}'..."
        podman network create "${NETWORK_NAME}" >/dev/null
        log_success "Network '${NETWORK_NAME}' created."
    fi
}

COMPOSE_CMD="podman compose"

usage() {
    cat <<EOF
Usage: $0 [command] [options]

Commands:
  up [service...]       Start the entire fleet or specified services (e.g. up donjo_backend)
  down                  Stop all services and infra
  build [service...]    Build Containerfile for all or specified services
  infra-up              Start RabbitMQ & Elasticsearch
  infra-down            Stop RabbitMQ & Elasticsearch
  status | ps           Show status of all running containers
  logs [service]        Follow logs of all containers or a specific service
  clean                 Stop containers and purge volumes
  help                  Show this help message

Microservice names:
  rabbitmq, elasticsearch, donjo_backend, donjo_event, donjo_booking,
  donjo_payment, donjo_search, donjo_ml, donjo_notifications, donjo_gateway

EOF
}

COMMAND="${1:-help}"

case "${COMMAND}" in
    up)
        ensure_socket
        ensure_network
        shift || true
        log_info "Starting services with Podman..."
        ${COMPOSE_CMD} up -d --build "$@"
        log_success "Services started."
        ;;
    down)
        ensure_socket
        log_info "Stopping services..."
        ${COMPOSE_CMD} down
        log_success "All services stopped."
        ;;
    build)
        ensure_socket
        shift || true
        log_info "Building container images..."
        ${COMPOSE_CMD} build "$@"
        log_success "Build complete."
        ;;
    infra-up)
        ensure_socket
        ensure_network
        log_info "Starting shared infrastructure (RabbitMQ + Elasticsearch)..."
        (cd infra && ${COMPOSE_CMD} up -d)
        log_success "Infrastructure running."
        ;;
    infra-down)
        ensure_socket
        log_info "Stopping shared infrastructure..."
        (cd infra && ${COMPOSE_CMD} down)
        log_success "Infrastructure stopped."
        ;;
    status|ps)
        log_info "Donjo Podman Containers:"
        podman ps --filter "network=${NETWORK_NAME}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Size}}"
        ;;
    logs)
        ensure_socket
        shift || true
        ${COMPOSE_CMD} logs -f "$@"
        ;;
    clean)
        ensure_socket
        log_warn "Stopping containers and removing volumes..."
        ${COMPOSE_CMD} down -v
        log_success "Cleanup complete."
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        log_error "Unknown command: ${COMMAND}"
        usage
        exit 1
        ;;
esac
