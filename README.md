# UltraFastKVCache

High-performance in-memory key-value store built with Go and fasthttp.

## Features

- **Sharded Cache**: Multiple shards with RWMutex for high concurrency
- **Fast HTTP API**: Powered by `fasthttp` for ultra-low latency
- **Optimized Docker**: Multi-stage build, non-root user, 13.5MB image
- **CI/CD Pipeline**: Automated testing, security scanning, and deployment

## Quick Start

```bash
# Build and run locally
make run

# Or with Docker
make docker-up

# Run with maximum performance (host networking)
make docker-up-host
```

## API Endpoints

### PUT /put
```bash
curl -X POST "http://localhost:7171/put" \
  -H "Content-Type: application/json" \
  -d '{"key":"name", "value":"UltraFastKV"}'
```

### GET /get
```bash
curl "http://localhost:7171/get?key=name"
```

## Makefile Commands

| Command | Description |
|---------|-------------|
| `make build` | Build the application |
| `make run` | Build and run locally |
| `make test` | Run unit tests |
| `make test-coverage` | Run tests with coverage report |
| `make lint` | Run golangci-lint |
| `make security-scan` | Run gosec and govulncheck |
| `make docker-build` | Build Docker image |
| `make docker-up` | Start optimized container |
| `make docker-up-host` | Start with host networking |
| `make docker-down` | Stop container |
| `make ci` | Run all CI checks locally |
| `make help` | Show all commands |

## CI/CD Pipeline

### Pipeline Architecture

```
┌─────────────────────────────────────────┐
│           CI - Build & Test             │
├─────────────────────────────────────────┤
│ • Checkout code                         │
│ • Setup Go 1.24                         │
│ • Lint (golangci-lint)                  │
│ • SAST (gosec)                          │
│ • SCA (govulncheck)                     │
│ • Unit Tests (75%+ coverage)            │
│ • Build binary                          │
└──────────────────┬──────────────────────┘
                   │ depends on CI
                   ▼
┌─────────────────────────────────────────┐
│          CD - Docker & Deploy           │
├─────────────────────────────────────────┤
│ • Build Docker image                    │
│ • Trivy vulnerability scan              │
│ • Container smoke test                  │
│ • Push to DockerHub                     │
└─────────────────────────────────────────┘
```

### Pipeline Stages

| Stage | Tool | Purpose |
|-------|------|---------|
| Linting | golangci-lint | Prevents technical debt |
| SAST | gosec, CodeQL | Detects OWASP Top 10 issues |
| SCA | govulncheck | Identifies supply-chain risks |
| Unit Tests | go test | Prevents regressions (75%+ coverage) |
| Build | go build | Validates compilation |
| Docker Build | docker | Creates container image |
| Image Scan | Trivy | Prevents vulnerable images |
| Smoke Test | curl | Ensures container is runnable |
| Registry Push | DockerHub | Enables deployment |

### Triggers

- **Push to main**: Full CI/CD with DockerHub push
- **Pull Request**: CI/CD without DockerHub push
- **Manual**: workflow_dispatch

## Security

### Security Scanning Tools

1. **gosec** - Go static security analyzer (SAST)
2. **govulncheck** - Go vulnerability checker (SCA)
3. **CodeQL** - GitHub's semantic code analysis
4. **Trivy** - Container vulnerability scanner

### Branch Protection

- Both `CI - Build & Test` and `CD - Docker & Deploy` must pass
- Strict mode enabled (branch must be up-to-date)

## Secrets Configuration

Configure these secrets in GitHub repository settings:

| Secret | Purpose |
|--------|---------|
| `DOCKERHUB_USERNAME` | Docker registry username |
| `DOCKERHUB_TOKEN` | Docker registry access token |

**Setup Steps:**
1. Go to [DockerHub](https://hub.docker.com) → Account Settings → Security
2. Create Access Token with Read/Write permissions
3. In GitHub repo: Settings → Secrets → Actions → New repository secret

## Docker Image

```bash
# Pull from DockerHub
docker pull varundeepsaini/kv-cache:latest

# Run with optimizations
docker run -d \
  --name kv-cache \
  -p 7171:7171 \
  --ulimit nofile=1048576:1048576 \
  varundeepsaini/kv-cache:latest
```

## Performance Optimizations

### Kernel Tuning (Optional)

For maximum performance, apply kernel optimizations:

```bash
make optimize-kernel
```

This configures:
- TCP connection queue and backlog
- Port reuse and TIME_WAIT handling
- Memory buffers for high throughput
- File descriptor limits

### Docker Optimizations

The `docker-up` and `docker-up-host` targets include:
- `--ulimit nofile=1048576:1048576` - High file descriptor limit
- `--ulimit memlock=-1:-1` - Unlimited memory locking
- `--network=host` (optional) - Eliminates network overhead

## Project Structure

```
.
├── .github/
│   └── workflows/
│       ├── ci.yml          # Main CI/CD pipeline
│       └── codeql.yml      # CodeQL security analysis
├── main.go                 # Application source
├── main_test.go            # Unit tests
├── Dockerfile              # Multi-stage Docker build
├── Makefile                # Build automation
├── go.mod                  # Go module definition
├── .golangci.yml           # Linter configuration
└── README.md               # This file
```

## License

MIT
