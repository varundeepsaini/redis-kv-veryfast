FROM golang:1.23-alpine

WORKDIR /app

COPY . .

RUN go build -o kv-cache .

EXPOSE 7171

CMD ["./kv-cache"]