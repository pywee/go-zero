package svc

import (
	"context"
	{{.configImport}}

	"github.com/pywee/{{.workName}}/cache"
	"github.com/pywee/{{.workName}}/model"
	"github.com/pywee/{{.workName}}/utils"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

type User struct{
	ID   int64  `json:"id"`
	Name string `json:"name"`
	Pic  string `json:"pic"`
}

type ServiceContext struct {
	Config {{.config}}
	RdsCli            *cache.RedisClientModel
	{{.middleware}}
}

func NewServiceContext(c {{.config}}) *ServiceContext {
	rdsCli := cache.Init(c.CacheRedis[0].Host, c.CacheRedis[0].Pass)
	db, _ := gorm.Open(mysql.Open(c.MysqlDB.DataSource), &gorm.Config{})
	_ = db
	return &ServiceContext{
		Config: c,
		RdsCli: rdsCli,
		{{.middlewareAssignment}}
	}
}

// User 获取上下文中的用户信息
func (l *ServiceContext) User(ctx context.Context) *User {
	if token := ctx.Value(utils.ContextType("token")); token != nil {
		var user User
		if ok, _ := l.RdsCli.GetCache(token.(string), &user); ok {
			return &user
		}
	}
	return nil
}

// UID 获取上下文中的用户ID
func (l *ServiceContext) UID(ctx context.Context) int64 {
	if user := l.User(ctx); user != nil {
		return user.ID
	}
	return 0
}
