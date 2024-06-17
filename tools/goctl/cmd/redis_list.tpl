package cache

import "time"

// LPush 将一个或多个值插入到列表头部
func (c *RedisClientModel) LPush(key string, values ...interface{}) error {
	if err := c.rdsCli.LPush(c.ctx, key, values...).Err(); c.IsRedisNotNil(err) {
		return err
	}
	return nil
}

// LPop 移出并获取列表的第一个元素
func (c *RedisClientModel) LPop(key string) (string, error) {
	ret, err := c.rdsCli.LPop(c.ctx, key).Result()
	if c.IsRedisNotNil(err) {
		return "", err
	}
	return ret, nil
}

// RPush 在列表中添加一个或多个值
func (c *RedisClientModel) RPush(key string, values ...interface{}) error {
	if err := c.rdsCli.RPush(c.ctx, key, values...).Err(); c.IsRedisNotNil(err) {
		return err
	}
	return nil
}

// RPop 移除列表的最后一个元素，返回值为移除的元素
func (c *RedisClientModel) RPop(key string) (string, error) {
	ret, err := c.rdsCli.RPop(c.ctx, key).Result()
	if c.IsRedisNotNil(err) {
		return "", err
	}
	return ret, nil
}

// BLPop 移出并获取列表的第一个元素
// 如果列表没有元素会阻塞列表直到等待超时或发现可弹出元素为止
func (c *RedisClientModel) BLPop(timeout time.Duration, keys ...string) ([]string, error) {
	ret, err := c.rdsCli.BLPop(c.ctx, timeout, keys...).Result()
	if c.IsRedisNotNil(err) {
		return nil, err
	}
	return ret, nil
}

// BRPop 移出并获取列表的最后一个元素， 如果列表没有元素会阻塞列表直到等待超时或发现可弹出元素为止
func (c *RedisClientModel) BRPop(timeout time.Duration, keys ...string) ([]string, error) {
	ret, err := c.rdsCli.BRPop(c.ctx, timeout, keys...).Result()
	if c.IsRedisNotNil(err) {
		return nil, err
	}
	return ret, nil
}

// LLen 获取列表长度
func (c *RedisClientModel) LLen(key string) int64 {
	return c.rdsCli.LLen(c.ctx, key).Val()
}

// LIndex 通过索引获取列表中的元素
func (c *RedisClientModel) LIndex(key string, value int64) string {
	return c.rdsCli.LIndex(c.ctx, key, value).Val()
}