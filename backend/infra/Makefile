# Podman-native Makefile for Backend Shared Infrastructure (RabbitMQ & Elasticsearch)

all: up

podman-init:
	@if [ ! -S "/run/user/$$(id -u)/podman/podman.sock" ]; then \
		systemctl --user start podman.socket 2>/dev/null || true; \
	fi
	@podman network exists donjo-net 2>/dev/null || podman network create donjo-net >/dev/null

up: podman-init
	@echo "Starting shared infrastructure (RabbitMQ + Elasticsearch) with Podman..."
	@podman compose up -d

down: podman-init
	@echo "Stopping shared infrastructure..."
	@podman compose down

logs: podman-init
	@podman compose logs -f

status:
	@podman ps --filter "name=rabbitmq" --filter "name=elasticsearch"

.PHONY: all podman-init up down logs status
