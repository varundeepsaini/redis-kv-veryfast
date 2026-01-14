.PHONY: build run test test-coverage lint docker-build docker-up docker-down smoke-test clean help

APP_NAME := kv-cache
DOCKER_IMAGE := kv-cache
DOCKER_TAG := latest
PORT := 7171

build:
	@echo "Building $(APP_NAME)..."
	go build -ldflags="-s -w" -o $(APP_NAME) .

run: build
	./$(APP_NAME)

test:
	go test -v ./...

test-coverage:
	go test -v -cover -coverprofile=coverage.out ./...
	go tool cover -func=coverage.out | grep total

lint:
	golangci-lint run --timeout=5m

docker-build:
	docker build -t $(DOCKER_IMAGE):$(DOCKER_TAG) .

docker-up: docker-build
	docker run -d \
		--name $(APP_NAME) \
		-p $(PORT):$(PORT) \
		--ulimit nofile=1048576:1048576 \
		--restart=unless-stopped \
		$(DOCKER_IMAGE):$(DOCKER_TAG)
	@echo "Running at http://localhost:$(PORT)"

docker-down:
	docker stop $(APP_NAME) || true
	docker rm $(APP_NAME) || true

smoke-test:
	@docker run -d --name smoke-test -p 7171:7171 $(DOCKER_IMAGE):$(DOCKER_TAG)
	@sleep 3
	@curl -sf -X POST http://localhost:7171/put -H "Content-Type: application/json" -d '{"key":"test","value":"smoke"}'
	@curl -sf http://localhost:7171/get?key=test | grep -q "smoke"
	@docker stop smoke-test && docker rm smoke-test
	@echo "Smoke test passed!"

clean:
	rm -f $(APP_NAME) coverage.out

help:
	@echo "make build         - Build binary"
	@echo "make run           - Build and run"
	@echo "make test          - Run tests"
	@echo "make test-coverage - Run tests with coverage"
	@echo "make lint          - Run linter"
	@echo "make docker-build  - Build Docker image"
	@echo "make docker-up     - Start container"
	@echo "make docker-down   - Stop container"
	@echo "make smoke-test    - Run smoke test"
	@echo "make clean         - Remove artifacts"
