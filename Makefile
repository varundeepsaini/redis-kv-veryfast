.PHONY: build run test test-coverage lint security-scan docker-build docker-run docker-up docker-down clean all

# Application
APP_NAME := kv-cache
DOCKER_IMAGE := kv-cache
DOCKER_TAG := latest
PORT := 7171

# Go flags
GO_BUILD_FLAGS := -ldflags="-s -w"

# ==================== Build ====================

build:
	@echo "Building $(APP_NAME)..."
	go build $(GO_BUILD_FLAGS) -o $(APP_NAME) .

run: build
	@echo "Running $(APP_NAME)..."
	./$(APP_NAME)

clean:
	@echo "Cleaning..."
	rm -f $(APP_NAME) coverage.out

# ==================== Testing ====================

test:
	@echo "Running tests..."
	go test -v ./...

test-coverage:
	@echo "Running tests with coverage..."
	go test -v -cover -coverprofile=coverage.out ./...
	go tool cover -func=coverage.out | grep total

test-coverage-html: test-coverage
	@echo "Generating HTML coverage report..."
	go tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report: coverage.html"

# ==================== Linting & Security ====================

lint:
	@echo "Running linter..."
	golangci-lint run --timeout=5m

security-scan:
	@echo "Running security scans..."
	@echo "=== gosec (SAST) ==="
	gosec ./...
	@echo "=== govulncheck (SCA) ==="
	govulncheck ./...

# ==================== Docker ====================

docker-build:
	@echo "Building Docker image..."
	docker build -t $(DOCKER_IMAGE):$(DOCKER_TAG) .

docker-run:
	@echo "Running Docker container..."
	docker run -p $(PORT):$(PORT) $(DOCKER_IMAGE):$(DOCKER_TAG)

docker-up: docker-build
	@echo "Starting optimized Docker container..."
	docker run -d \
		--name $(APP_NAME) \
		-p $(PORT):$(PORT) \
		--ulimit nofile=1048576:1048576 \
		--ulimit memlock=-1:-1 \
		--memory=512m \
		--cpus=2 \
		--restart=unless-stopped \
		$(DOCKER_IMAGE):$(DOCKER_TAG)
	@echo "Container started: $(APP_NAME)"
	@echo "API available at: http://localhost:$(PORT)"

docker-up-host: docker-build
	@echo "Starting Docker container with host networking (maximum performance)..."
	docker run -d \
		--name $(APP_NAME) \
		--network=host \
		--ulimit nofile=1048576:1048576 \
		--ulimit memlock=-1:-1 \
		--restart=unless-stopped \
		$(DOCKER_IMAGE):$(DOCKER_TAG)
	@echo "Container started: $(APP_NAME)"
	@echo "API available at: http://localhost:$(PORT)"

docker-down:
	@echo "Stopping and removing container..."
	docker stop $(APP_NAME) || true
	docker rm $(APP_NAME) || true

docker-logs:
	docker logs -f $(APP_NAME)

docker-shell:
	docker exec -it $(APP_NAME) /bin/sh

# ==================== Kernel Optimizations ====================

optimize-kernel:
	@echo "Applying kernel optimizations (requires sudo)..."
	sudo sysctl -w net.core.somaxconn=131072
	sudo sysctl -w net.core.netdev_max_backlog=500000
	sudo sysctl -w net.ipv4.tcp_tw_reuse=1
	sudo sysctl -w net.ipv4.tcp_fin_timeout=10
	sudo sysctl -w net.ipv4.tcp_max_syn_backlog=262144
	sudo sysctl -w net.ipv4.tcp_syncookies=0
	sudo sysctl -w net.ipv4.tcp_mem="786432 1048576 1572864"
	sudo sysctl -w net.ipv4.tcp_rmem="4096 87380 6291456"
	sudo sysctl -w net.ipv4.tcp_wmem="4096 87380 6291456"
	sudo sysctl -w net.ipv4.ip_local_port_range="1024 65535"
	sudo sysctl -w net.ipv4.tcp_fastopen=3
	sudo sysctl -w fs.file-max=2097152
	sudo sysctl -w net.ipv4.tcp_keepalive_time=60
	sudo sysctl -w net.ipv4.tcp_keepalive_intvl=10
	sudo sysctl -w net.ipv4.tcp_keepalive_probes=5
	@echo "Kernel optimizations applied!"

# ==================== CI/CD Local ====================

ci: lint test-coverage security-scan build
	@echo "CI checks passed!"

# ==================== All ====================

all: clean lint test-coverage security-scan build docker-build
	@echo "All tasks completed!"

# ==================== Help ====================

help:
	@echo "Available targets:"
	@echo "  build            - Build the application"
	@echo "  run              - Build and run the application"
	@echo "  clean            - Remove build artifacts"
	@echo ""
	@echo "  test             - Run tests"
	@echo "  test-coverage    - Run tests with coverage report"
	@echo "  test-coverage-html - Generate HTML coverage report"
	@echo ""
	@echo "  lint             - Run golangci-lint"
	@echo "  security-scan    - Run gosec and govulncheck"
	@echo ""
	@echo "  docker-build     - Build Docker image"
	@echo "  docker-run       - Run Docker container"
	@echo "  docker-up        - Start optimized container (detached)"
	@echo "  docker-up-host   - Start with host networking (max performance)"
	@echo "  docker-down      - Stop and remove container"
	@echo "  docker-logs      - View container logs"
	@echo "  docker-shell     - Shell into container"
	@echo ""
	@echo "  optimize-kernel  - Apply kernel optimizations (requires sudo)"
	@echo "  ci               - Run all CI checks locally"
	@echo "  all              - Run everything"
