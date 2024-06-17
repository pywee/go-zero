package cache

import redis "github.com/redis/go-redis/v9"

// ZAdd 向有序集合添加一个或多个成员，或者更新已存在成员的分数
func (c *RedisClientModel) ZAdd(key string, members ...redis.Z) (int64, error) {
	ret, err := c.rdsCli.ZAdd(c.ctx, key, members...).Result()
	if c.IsRedisNotNil(err) {
		return 0, err
	}
	return ret, nil
}

// ZCard 获取有序集合的成员数
func (c *RedisClientModel) ZCard(key string) int64 {
	return c.rdsCli.ZCard(c.ctx, key).Val()
}

// ZCount 计算在有序集合中指定区间分数的成员数
func (c *RedisClientModel) ZCount(key, min, max string) int64 {
	return c.rdsCli.ZCount(c.ctx, key, min, max).Val()
}

// ZIncrBy 有序集合中对指定成员的分数加上增量 increment
func (c *RedisClientModel) ZIncrBy(key string, increment float64, member string) (float64, error) {
	ret, err := c.rdsCli.ZIncrBy(c.ctx, key, increment, member).Result()
	if c.IsRedisNotNil(err) {
		return 0, err
	}
	return ret, nil
}
