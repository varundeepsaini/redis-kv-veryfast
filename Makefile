build:
	go build -o kv-cache .

run:
	./kv-cache

docker-build:
	docker build -t kv-cache .

docker-run:
	docker run -p 7171:7171 kv-cache