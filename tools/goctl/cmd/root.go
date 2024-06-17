package cmd

import (
	_ "embed"
	"errors"
	"fmt"
	"os"
	"runtime"
	"strings"
	"text/template"

	"github.com/gookit/color"
	"github.com/spf13/cobra"
	cobracompletefig "github.com/withfig/autocomplete-tools/integrations/cobra"
	"github.com/zeromicro/go-zero/tools/goctl/api"
	"github.com/zeromicro/go-zero/tools/goctl/bug"
	"github.com/zeromicro/go-zero/tools/goctl/docker"
	"github.com/zeromicro/go-zero/tools/goctl/env"
	"github.com/zeromicro/go-zero/tools/goctl/gateway"
	"github.com/zeromicro/go-zero/tools/goctl/internal/cobrax"
	"github.com/zeromicro/go-zero/tools/goctl/internal/version"
	"github.com/zeromicro/go-zero/tools/goctl/kube"
	"github.com/zeromicro/go-zero/tools/goctl/migrate"
	"github.com/zeromicro/go-zero/tools/goctl/model"
	"github.com/zeromicro/go-zero/tools/goctl/quickstart"
	"github.com/zeromicro/go-zero/tools/goctl/rpc"
	"github.com/zeromicro/go-zero/tools/goctl/tpl"
	"github.com/zeromicro/go-zero/tools/goctl/upgrade"
)

const (
	codeFailure = 1
	dash        = "-"
	doubleDash  = "--"
	assign      = "="
)

var (
	//go:embed usage.tpl
	usageTpl string
	rootCmd  = cobrax.NewCommand("goctl")
)

// Execute executes the given command
func Execute() {
	os.Args = supportGoStdFlag(os.Args)
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(color.Red.Render(err.Error()))
		os.Exit(codeFailure)
	}
}

func supportGoStdFlag(args []string) []string {
	copyArgs := append([]string(nil), args...)
	parentCmd, _, err := rootCmd.Traverse(args[:1])
	if err != nil { // ignore it to let cobra handle the error.
		return copyArgs
	}

	for idx, arg := range copyArgs[0:] {
		parentCmd, _, err = parentCmd.Traverse([]string{arg})
		if err != nil { // ignore it to let cobra handle the error.
			break
		}
		if !strings.HasPrefix(arg, dash) {
			continue
		}

		flagExpr := strings.TrimPrefix(arg, doubleDash)
		flagExpr = strings.TrimPrefix(flagExpr, dash)
		flagName, flagValue := flagExpr, ""
		assignIndex := strings.Index(flagExpr, assign)
		if assignIndex > 0 {
			flagName = flagExpr[:assignIndex]
			flagValue = flagExpr[assignIndex:]
		}

		if !isBuiltin(flagName) {
			// The method Flag can only match the user custom flags.
			f := parentCmd.Flag(flagName)
			if f == nil {
				continue
			}
			if f.Shorthand == flagName {
				continue
			}
		}

		goStyleFlag := doubleDash + flagName
		if assignIndex > 0 {
			goStyleFlag += flagValue
		}

		copyArgs[idx] = goStyleFlag
	}
	return copyArgs
}

func isBuiltin(name string) bool {
	return name == "version" || name == "help"
}

func init() {
	cobra.AddTemplateFuncs(template.FuncMap{
		"blue":    blue,
		"green":   green,
		"rpadx":   rpadx,
		"rainbow": rainbow,
	})

	rootCmd.Version = fmt.Sprintf(
		"%s %s/%s", version.BuildVersion,
		runtime.GOOS, runtime.GOARCH)

	rootCmd.SetUsageTemplate(usageTpl)
	rootCmd.AddCommand(api.Cmd, bug.Cmd, docker.Cmd, kube.Cmd, env.Cmd, gateway.Cmd, model.Cmd)
	rootCmd.AddCommand(migrate.Cmd, quickstart.Cmd, rpc.Cmd, tpl.Cmd, upgrade.Cmd)
	rootCmd.Command.AddCommand(cobracompletefig.CreateCompletionSpecCommand())

	createCacheFile()
	rootCmd.MustInit()
}

func createCacheFile() error {
	c, _ := os.Getwd()
	if c == "" {
		return errors.New("can not find cache dir")
	}
	dir := c + "/cache"
	if !directoryExists(dir) {
		return os.Mkdir(dir, 0755)
	}

	files := map[string]string{
		"/cache.go":        redisCache,
		"/init.go":         redisInit,
		"/redis_hash.go":   redisHash,
		"/redis_key.go":    redisKey,
		"/redis_list.go":   redisList,
		"/redis_string.go": redisString,
		"/redis_set.go":    redisSet,
		"/redis_sorted.go": redisSorted,
	}
	for path, file := range files {
		if err := os.WriteFile(dir+path, []byte(file), 0666); err != nil {
			return err
		}
	}

	return nil
}

func directoryExists(path string) bool {
	info, err := os.Stat(path)
	if os.IsNotExist(err) {
		return false
	}
	if err != nil {
		return false
	}
	return info.IsDir()
}

var redisCache = `
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

	log.Printf("set cache finished of key %s", key)
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

	log.Println("<- get DATA cache", key)
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
`

var redisInit = `
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
`

var redisHash = `
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
`
var redisString = `
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
`

var redisList = `
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
`

var redisSorted = `
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
`

var redisKey = `
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
`

var redisSet = `
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
`
