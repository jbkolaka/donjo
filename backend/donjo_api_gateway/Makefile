# Podman-native Makefile for donjo_api_gateway
APP_NAME = donjo_gateway

all: build test

build:
	@echo "Building binary..."
	@CGO_ENABLED=0 GOOS=linux go build -o main cmd/api/main.go

run:
	@go run cmd/api/main.go

podman-init:
	@if [ ! -S "/run/user/$$(id -u)/podman/podman.sock" ]; then \
		systemctl --user start podman.socket 2>/dev/null || true; \
	fi
	@podman network exists donjo-net 2>/dev/null || podman network create donjo-net >/dev/null

podman-build:
	@echo "Building Podman container for $(APP_NAME)..."
	@podman build -t localhost/$(APP_NAME):latest -f Containerfile .

podman-up: podman-init
	@echo "Starting $(APP_NAME) container..."
	@podman compose up -d --build

podman-down:
	@echo "Stopping $(APP_NAME) container..."
	@podman compose down

podman-logs:
	@podman logs -f $(APP_NAME)

# Aliases
docker-run: podman-up
docker-down: podman-down
up: podman-up
down: podman-down

test:
	@echo "Testing..."
	@go test ./... -v

clean:
	@echo "Cleaning..."
	@rm -f main

# Live Reload
watch:
	@if command -v air > /dev/null; then \
		air; \
		echo "Watching..."; \
	else \
		read -p "Go's 'air' is not installed on your machine. Do you want to install it? [Y/n] " choice; \
		if [ "$$choice" != "n" ] && [ "$$choice" != "N" ]; then \
			go install github.com/air-verse/air@latest; \
			air; \
			echo "Watching..."; \
		else \
			echo "You chose not to install air. Exiting..."; \
			exit 1; \
		fi; \
	fi

.PHONY: all build run test clean watch podman-init podman-build podman-up podman-down podman-logs docker-run docker-down up down
