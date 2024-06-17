package cache

import (
	"time"
)

// Set 设置指定 key 的值
func (c *RedisClientModel) Set(key string, value interface{}, expireTs time.Duration) error {
	if err := c.rdsCli.Set(c.ctx, key, value, expireTs).Err(); c.IsRedisNotNil(err) {
		return err
	}
	return nil
}

// Get 获取指定 key 的值
func (c *RedisClientModel) Get(key string) (string, error) {
	ret, err := c.rdsCli.Get(c.ctx, key).Result()
	if c.IsRedisNotNil(err) {
		return "", err
	}
	return ret, nil
}

// GetBytes 获取指定 key 的值
func (c *RedisClientModel) GetBytes(key string) []byte {
	ret, err := c.rdsCli.Get(c.ctx, key).Bytes()
	if c.IsRedisNotNil(err) {
		return nil
	}
	return ret
}

// GetSet 获取指定 key 的值
func (c *RedisClientModel) GetSet(key string, value interface{}) (string, error) {
	ret, err := c.rdsCli.GetSet(c.ctx, key, value).Result()
	if c.IsRedisNotNil(err) {
		return "", err
	}
	return ret, nil
}

// MSet 同时设置一个或多个 key-value 对
func (c *RedisClientModel) MSet(values ...string) {
	c.rdsCli.MSet(c.ctx, values)
}

// MGet 获取所有(一个或多个)给定 key 的值
func (c *RedisClientModel) MGet(key ...string) []interface{} {
	return c.rdsCli.MGet(c.ctx, key...).Val()
}

// SetBit 将给定 key 的值设为 value ，并返回 key 的旧值(old value)
func (c *RedisClientModel) SetBit(key string, offset int64, value int) (int64, error) {
	ret, err := c.rdsCli.SetBit(c.ctx, key, offset, value).Result()
	if c.IsRedisNotNil(err) {
		return 0, err
	}
	return ret, nil
}

// GetBit 对 key 所储存的字符串值，获取指定偏移量上的位(bit)
func (c *RedisClientModel) GetBit(key string, offset int64, value int) int64 {
	return c.rdsCli.GetBit(c.ctx, key, offset).Val()
}

// SetNX 只有在 key 不存在时设置 key 的值
func (c *RedisClientModel) SetNX(key string, value interface{}, expireTs time.Duration) bool {
	return c.rdsCli.SetNX(c.ctx, key, value, expireTs).Val()
}

// StrLen 返回 key 所储存的字符串值的长度
func (c *RedisClientModel) StrLen(key string, value int64) int64 {
	return c.rdsCli.StrLen(c.ctx, key).Val()
}

// Incr 计数器
func (c *RedisClientModel) Incr(key string) int64 {
	return c.rdsCli.Incr(c.ctx, key).Val()
}

// IncrBy 计数器
func (c *RedisClientModel) IncrBy(key string, value int64) int64 {
	return c.rdsCli.IncrBy(c.ctx, key, value).Val()
}

// Decr 计数器
func (c *RedisClientModel) Decr(key string) int64 {
	return c.rdsCli.Decr(c.ctx, key).Val()
}

// DecrBy 计数器
func (c *RedisClientModel) DecrBy(key string, value int64) int64 {
	return c.rdsCli.DecrBy(c.ctx, key, value).Val()
}

// Append 如果 key 已经存在并且是一个字符串
// APPEND 命令将指定的 value 追加到该 key 原来值 (value) 的末尾
func (c *RedisClientModel) Append(key, value string) (int64, error) {
	ret, err := c.rdsCli.Append(c.ctx, key, value).Result()
	if c.IsRedisNotNil(err) {
		return 0, err
	}
	return ret, nil
}