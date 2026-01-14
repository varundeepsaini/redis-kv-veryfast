package main

import (
	"encoding/json"
	"testing"

	"github.com/valyala/fasthttp"
)

// Test CacheShard operations
func TestCacheShard_PutAndGet(t *testing.T) {
	shard := NewCacheShard()

	shard.Put("key1", "value1")
	val, ok := shard.Get("key1")

	if !ok {
		t.Fatal("expected key1 to exist")
	}
	if val != "value1" {
		t.Fatalf("expected value1, got %s", val)
	}
}

func TestCacheShard_GetMissing(t *testing.T) {
	shard := NewCacheShard()

	_, ok := shard.Get("nonexistent")
	if ok {
		t.Fatal("expected key to not exist")
	}
}

func TestCacheShard_Update(t *testing.T) {
	shard := NewCacheShard()

	shard.Put("key1", "value1")
	shard.Put("key1", "value2")

	val, ok := shard.Get("key1")
	if !ok {
		t.Fatal("expected key1 to exist")
	}
	if val != "value2" {
		t.Fatalf("expected value2, got %s", val)
	}
}

// Test hash function
func TestDjb2Hash(t *testing.T) {
	hash1 := djb2Hash("test")
	hash2 := djb2Hash("test")

	if hash1 != hash2 {
		t.Fatal("same input should produce same hash")
	}

	hash3 := djb2Hash("different")
	if hash1 == hash3 {
		t.Fatal("different inputs should produce different hashes")
	}
}

// Test ShardedCache operations
func TestShardedCache_PutAndGet(t *testing.T) {
	sc := NewShardedCache(4)

	sc.Put("key1", "value1")
	val, ok := sc.Get("key1")

	if !ok {
		t.Fatal("expected key1 to exist")
	}
	if val != "value1" {
		t.Fatalf("expected value1, got %s", val)
	}
}

func TestShardedCache_MultipleKeys(t *testing.T) {
	sc := NewShardedCache(4)

	for i := 0; i < 100; i++ {
		key := string(rune('a' + i%26))
		sc.Put(key, key+"_value")
	}

	val, ok := sc.Get("a")
	if !ok {
		t.Fatal("expected key 'a' to exist")
	}
	if val != "a_value" {
		t.Fatalf("expected a_value, got %s", val)
	}
}

// Test HTTP handlers
func TestRequestHandler_Put(t *testing.T) {
	cache = NewShardedCache(4)

	ctx := &fasthttp.RequestCtx{}
	ctx.Request.Header.SetMethod("POST")
	ctx.Request.SetRequestURI("/put")
	ctx.Request.SetBody([]byte(`{"key":"testkey","value":"testvalue"}`))

	requestHandler(ctx)

	if ctx.Response.StatusCode() != 200 {
		t.Fatalf("expected 200, got %d", ctx.Response.StatusCode())
	}

	val, ok := cache.Get("testkey")
	if !ok {
		t.Fatal("expected testkey to exist in cache")
	}
	if val != "testvalue" {
		t.Fatalf("expected testvalue, got %s", val)
	}
}

func TestRequestHandler_Get(t *testing.T) {
	cache = NewShardedCache(4)
	cache.Put("testkey", "testvalue")

	ctx := &fasthttp.RequestCtx{}
	ctx.Request.Header.SetMethod("GET")
	ctx.Request.SetRequestURI("/get?key=testkey")

	requestHandler(ctx)

	if ctx.Response.StatusCode() != 200 {
		t.Fatalf("expected 200, got %d", ctx.Response.StatusCode())
	}

	var resp GetResponse
	if err := json.Unmarshal(ctx.Response.Body(), &resp); err != nil {
		t.Fatalf("failed to unmarshal response: %v", err)
	}

	if resp.Status != "OK" {
		t.Fatalf("expected OK status, got %s", resp.Status)
	}
	if resp.Value != "testvalue" {
		t.Fatalf("expected testvalue, got %s", resp.Value)
	}
}

func TestRequestHandler_GetNotFound(t *testing.T) {
	cache = NewShardedCache(4)

	ctx := &fasthttp.RequestCtx{}
	ctx.Request.Header.SetMethod("GET")
	ctx.Request.SetRequestURI("/get?key=nonexistent")

	requestHandler(ctx)

	body := string(ctx.Response.Body())
	if body != `{"status":"ERROR","message":"Key not found."}` {
		t.Fatalf("unexpected response: %s", body)
	}
}

func TestRequestHandler_PutEmptyKey(t *testing.T) {
	cache = NewShardedCache(4)

	ctx := &fasthttp.RequestCtx{}
	ctx.Request.Header.SetMethod("POST")
	ctx.Request.SetRequestURI("/put")
	ctx.Request.SetBody([]byte(`{"key":"","value":"testvalue"}`))

	requestHandler(ctx)

	if ctx.Response.StatusCode() != 400 {
		t.Fatalf("expected 400, got %d", ctx.Response.StatusCode())
	}
}

func TestRequestHandler_InvalidPath(t *testing.T) {
	cache = NewShardedCache(4)

	ctx := &fasthttp.RequestCtx{}
	ctx.Request.Header.SetMethod("GET")
	ctx.Request.SetRequestURI("/invalid")

	requestHandler(ctx)

	if ctx.Response.StatusCode() != 404 {
		t.Fatalf("expected 404, got %d", ctx.Response.StatusCode())
	}
}

func TestRequestHandler_PutBadJSON(t *testing.T) {
	cache = NewShardedCache(4)

	ctx := &fasthttp.RequestCtx{}
	ctx.Request.Header.SetMethod("POST")
	ctx.Request.SetRequestURI("/put")
	ctx.Request.SetBody([]byte(`{invalid json}`))

	requestHandler(ctx)

	if ctx.Response.StatusCode() != 400 {
		t.Fatalf("expected 400, got %d", ctx.Response.StatusCode())
	}
}

func TestRequestHandler_PutKeyTooLong(t *testing.T) {
	cache = NewShardedCache(4)

	longKey := string(make([]byte, 300))
	ctx := &fasthttp.RequestCtx{}
	ctx.Request.Header.SetMethod("POST")
	ctx.Request.SetRequestURI("/put")
	ctx.Request.SetBody([]byte(`{"key":"` + longKey + `","value":"v"}`))

	requestHandler(ctx)

	if ctx.Response.StatusCode() != 400 {
		t.Fatalf("expected 400, got %d", ctx.Response.StatusCode())
	}
}

func TestRequestHandler_GetMissingKeyParam(t *testing.T) {
	cache = NewShardedCache(4)

	ctx := &fasthttp.RequestCtx{}
	ctx.Request.Header.SetMethod("GET")
	ctx.Request.SetRequestURI("/get")

	requestHandler(ctx)

	if ctx.Response.StatusCode() != 400 {
		t.Fatalf("expected 400, got %d", ctx.Response.StatusCode())
	}
}

func TestCacheShard_Eviction(t *testing.T) {
	shard := NewCacheShard()

	for i := 0; i < 700001; i++ {
		shard.Put(string(rune(i)), "value")
	}

	shard.Put("finalkey", "finalvalue")
	val, ok := shard.Get("finalkey")
	if !ok || val != "finalvalue" {
		t.Fatal("expected finalkey to exist after eviction")
	}
}
