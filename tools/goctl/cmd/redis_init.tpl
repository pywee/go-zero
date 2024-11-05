package cache

import (
	"context"
	"sync"
	"time"

	"github.com/redis/go-redis/v9"
)

// 2024.04.19 两次封装

type RedisClientModel struct {
	lk     *sync.Mutex
	rdsCli *redis.Client
	ctx    context.Context
	TimeOut time.Duration
}

// Init 创建 redis 客户端
func Init(host, pwd string, t time.Duration) *RedisClientModel {
	return &RedisClientModel{
		lk:  &sync.Mutex{},
		ctx: context.Background(),
		TimeOut: t,
		rdsCli: redis.NewClient(&redis.Options{
			Addr:     host,
			Password: pwd,
			DB:       0,
			PoolSize: 10,
		}),
	}
}