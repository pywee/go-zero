package cache

import (
	"context"
	"sync"

	"github.com/redis/go-redis/v9"
)

// 2024.04.19 两次封装

type RedisClientModel struct {
	lk     *sync.Mutex
	rdsCli *redis.Client
	ctx    context.Context
}

// Init 创建 redis 客户端
func Init(host, pwd string) *RedisClientModel {
	return &RedisClientModel{
		lk:  &sync.Mutex{},
		ctx: context.Background(),
		rdsCli: redis.NewClient(&redis.Options{
			Addr:     host,
			Password: pwd,
			DB:       0,
			PoolSize: 10,
		}),
	}
}