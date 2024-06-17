package cache

// SAdd 向集合添加一个或多个成员
func (c *RedisClientModel) SAdd(key string, members ...interface{}) error {
	if err := c.rdsCli.SAdd(c.ctx, key, members).Err(); c.IsRedisNotNil(err) {
		return err
	}
	return nil
}

// SCard 获取集合的成员数
func (c *RedisClientModel) SCard(key string) int64 {
	return c.rdsCli.SCard(c.ctx, key).Val()
}

// Sdiff 返回第一个集合与其他集合之间的差异
func (c *RedisClientModel) Sdiff(keys ...string) []string {
	return c.rdsCli.SDiff(c.ctx, keys...).Val()
}

// SDiffStore 返回给定所有集合的差集并存储在 destination 中
func (c *RedisClientModel) SDiffStore(destination *string, keys ...string) int64 {
	return c.rdsCli.SDiffStore(c.ctx, *destination, keys...).Val()
}

// SInter 返回给定所有集合的交集
func (c *RedisClientModel) SInter(keys ...string) []string {
	return c.rdsCli.SInter(c.ctx, keys...).Val()
}

// SInterStore 返回给定所有集合的交集并存储在 destination 中
func (c *RedisClientModel) SInterStore(destination *string, keys ...string) int64 {
	return c.rdsCli.SInterStore(c.ctx, *destination, keys...).Val()
}

// SIsMember 判断 member 元素是否是集合 key 的成员
func (c *RedisClientModel) SIsMember(key string, member interface{}) bool {
	return c.rdsCli.SIsMember(c.ctx, key, member).Val()
}

// SMembers 返回集合中的所有成员
func (c *RedisClientModel) SMembers(key string) []string {
	return c.rdsCli.SMembers(c.ctx, key).Val()
}

// Spop 移除并返回集合中的一个随机元素
func (c *RedisClientModel) Spop(key string) string {
	return c.rdsCli.SPop(c.ctx, key).Val()
}

// SRem 移除集合中一个或多个成员
func (c *RedisClientModel) SRem(key string, members ...interface{}) int64 {
	return c.rdsCli.SRem(c.ctx, key, members).Val()
}

// SUnion 移除集合中一个或多个成员
func (c *RedisClientModel) SUnion(key ...string) []string {
	return c.rdsCli.SUnion(c.ctx, key...).Val()
}