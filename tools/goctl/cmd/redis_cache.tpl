package cache

import (
	"context"
	"encoding/json"
	"errors"
	"log"
	"strings"
	"time"
)

// cc.SetCache("article:111", &Demo{Uid: 39010}, time.Second*10)
// cc.SetCache("article:222", &Demo{Uid: 39010}, time.Second*10)
// cc.DelCache("article*")

// var user = new(Demo)
// cc.GetCache("article:111", user)
// fmt.Println(user)

// SetCache 设置缓存
func (c *RedisClientModel) SetCache(key string, value interface{}, expireTs time.Duration) bool {
	if c == nil {
		log.Printf("cache is nil")
		return false
	}
	if key == "" {
		log.Printf("cache key can not be empty")
		return false
	}

	var (
		err error
		buf []byte
	)
	if buf, err = json.Marshal(value); err != nil {
		log.Printf("fail to marshal cache with key: %s, value: %v", key, value)
		return false
	}

	ctx, cancel := context.WithTimeout(context.Background(), time.Second*10)
	defer cancel()

	if err = c.rdsCli.Set(ctx, key, buf, expireTs).Err(); c.IsRedisNotNil(err) {
		log.Printf("fail to set data into redis, key:%s, reason: %s", key, err.Error())
		return false
	}

	log.Println("-> set DATA cache of key:", key)
	return true
}

// GetCache 获取缓存
func (c *RedisClientModel) GetCache(key string, value interface{}) (bool, error) {
	if c == nil {
		log.Println("c == nil, redis cache")
		return false, errors.New("redis not found")
	}

	var (
		err error
		ret []byte
	)

	if ret, err = c.rdsCli.Get(c.ctx, key).Bytes(); c.IsRedisNotNil(err) {
		log.Printf("redis cache error not nil %v %s", err, key)
		return false, err
	}
	if len(ret) == 0 {
		log.Printf("no cache data in redis for this key, %v %s  %v", err, key, ret)
		return false, nil
	}
	if err = json.Unmarshal(ret, value); err != nil {
		log.Printf("redis cache error not nil 3 %v %s %v", err, key, value)
		return false, err
	}

	log.Println("<- get DATA cache of key:", key)
	return true, nil
}

// DelCache 查找并删除符合给定模式(pattern)的 key
func (c *RedisClientModel) DelCache(pattern string) bool {
	if c == nil {
		log.Printf("cache hasn't enable")
		return false
	}

	if !strings.Contains(pattern, "*") {
		log.Println("- will delete cache", pattern)
		if err := c.rdsCli.Del(c.ctx, pattern).Err(); c.IsRedisNotNil(err) {
			log.Printf("method DelCache() fail to del rds key %s", pattern)
			return false
		}
	}

	if keys := c.Keys(pattern); len(keys) > 0 {
		log.Println("- will delete cache", keys)
		if err := c.rdsCli.Del(c.ctx, keys...).Err(); c.IsRedisNotNil(err) {
			log.Printf("fail to del cache, reason: %s", err.Error())
			return false
		}
	}
	return true
}

// IsRedisNotNil 检查 redis 返回值是否有错误输出
func (c *RedisClientModel) IsRedisNotNil(err error) bool {
	if err == nil {
		return false
	}
	return err.Error() != "redis: nil"
}