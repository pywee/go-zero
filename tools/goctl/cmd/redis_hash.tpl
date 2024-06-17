package cache

// HSet 将哈希表 key 中的字段 field 的值设为 value
func (c *RedisClientModel) HSet(key, field string, value interface{}) error {
	if err := c.rdsCli.HSet(c.ctx, key, field, value).Err(); c.IsRedisNotNil(err) {
		return err
	}
	return nil
}

// HGet 获取存储在哈希表中指定字段的值
func (c *RedisClientModel) HGet(key, field string) (string, error) {
	ret, err := c.rdsCli.HGet(c.ctx, key, field).Result()
	if c.IsRedisNotNil(err) {
		return "", err
	}
	return ret, nil
}

// HGetINT 获取存储在哈希表中指定字段的值
func (c *RedisClientModel) HGetINT(key, field string) (int64, error) {
	ret, err := c.rdsCli.HGet(c.ctx, key, field).Int64()
	if c.IsRedisNotNil(err) {
		return 0, err
	}
	return ret, nil
}

// HMSet 同时将多个 field-value (域-值)对设置到哈希表 key 中
func (c *RedisClientModel) HMSet(key, field string, value interface{}) bool {
	return c.rdsCli.HMSet(c.ctx, key, field, value).Val()
}

// HMGet 获取所有给定字段的值
func (c *RedisClientModel) HMGet(key, field string, value interface{}) []interface{} {
	return c.rdsCli.HMGet(c.ctx, key, field).Val()
}

// HDel 删除一个或多个哈希表字段
func (c *RedisClientModel) HDel(key, field string) int64 {
	return c.rdsCli.HDel(c.ctx, key, field).Val()
}

// HExists 查看哈希表 key 中指定的字段是否存在
func (c *RedisClientModel) HExists(key, field string) bool {
	return c.rdsCli.HExists(c.ctx, key, field).Val()
}

// HGetAll 获取在哈希表中指定 key 的所有字段和值
func (c *RedisClientModel) HGetAll(key, field string) map[string]string {
	return c.rdsCli.HGetAll(c.ctx, key).Val()
}

// HKeys 获取所有哈希表中的字段
func (c *RedisClientModel) HKeys(key string) []string {
	return c.rdsCli.HKeys(c.ctx, key).Val()
}

// HVals 获取哈希表中所有值
func (c *RedisClientModel) HVals(key string) []string {
	return c.rdsCli.HVals(c.ctx, key).Val()
}

// HLen 获取哈希表中字段的数量
func (c *RedisClientModel) HLen(key string) int64 {
	return c.rdsCli.HLen(c.ctx, key).Val()
}

// HSetNX 哈希设置
func (c *RedisClientModel) HSetNX(key, field string, value interface{}) bool {
	return c.rdsCli.HSetNX(c.ctx, key, field, value).Val()
}