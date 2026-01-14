FROM golang:1.24-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o kv-cache .

FROM alpine:3.23

RUN apk add --no-cache curl && adduser -D -g '' appuser

COPY --from=builder /app/kv-cache /kv-cache

USER appuser

EXPOSE 7171

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -sf http://localhost:7171/get?key=health || exit 1

CMD ["/kv-cache"]
