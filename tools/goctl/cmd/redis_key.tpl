package cache

import "time"

// Exists 检查给定 key 是否存在
func (c *RedisClientModel) Exists(key string) int64 {
	return c.rdsCli.Exists(c.ctx, key).Val()
}

// Del 该命令用于在 key 存在时删除 key
// 返回被删除的 key 的数量
func (c *RedisClientModel) Del(key string) int64 {
	return c.rdsCli.Del(c.ctx, key).Val()
}

// Expire 为给定 key 设置过期时间，以秒计
func (c *RedisClientModel) Expire(key string, expire time.Duration) bool {
	return c.rdsCli.Expire(c.ctx, key, expire).Val()
}

// PExpire 设置 key 过期时间的时间戳(unix timestamp) 以毫秒计
func (c *RedisClientModel) PExpire(key string, expire time.Duration) bool {
	return c.rdsCli.PExpire(c.ctx, key, expire).Val()
}

// ExpireAt EXPIREAT 的作用和 EXPIRE 类似，都用于为 key 设置过期时间
// 不同在于 EXPIREAT 命令接受的时间参数是 UNIX 时间戳(unix timestamp)
func (c *RedisClientModel) ExpireAt(key string, expire time.Time) bool {
	return c.rdsCli.ExpireAt(c.ctx, key, expire).Val()
}

// Keys 查找所有符合给定模式(pattern)的 key
// 设置 key:1 key:2
// 查找时 key:* 必须加入一个通配符才能找到
func (c *RedisClientModel) Keys(pattern string) []string {
	return c.rdsCli.Keys(c.ctx, pattern).Val()
}

// Type 返回 key 的数据类型，数据类型有：
// * none (key不存在)
// * string (字符串)
// * list (列表)
// * set (集合)
// * zset (有序集)
// * hash (哈希表)
func (c *RedisClientModel) Type(key string) string {
	return c.rdsCli.Type(c.ctx, key).Val()
}

// Persist 移除 key 的过期时间, key 将持久保持
func (c *RedisClientModel) Persist(key string) bool {
	return c.rdsCli.Persist(c.ctx, key).Val()
}

// TTL 以秒为单位，返回给定 key 的剩余生存时间(TTL, time to live)
func (c *RedisClientModel) TTL(key string) time.Duration {
	return c.rdsCli.TTL(c.ctx, key).Val()
}

// PTTL 以毫秒为单位返回 key 的剩余的过期时间
func (c *RedisClientModel) PTTL(key string) time.Duration {
	return c.rdsCli.PTTL(c.ctx, key).Val()
}