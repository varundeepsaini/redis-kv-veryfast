FROM golang:1.24-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o kv-cache .

FROM alpine:3.21

RUN adduser -D -g '' appuser

COPY --from=builder /app/kv-cache /kv-cache

USER appuser

EXPOSE 7171

CMD ["/kv-cache"]
