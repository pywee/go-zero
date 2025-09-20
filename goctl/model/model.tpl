package {{.pkg}}
{{if .withCache}}
import (
	"context"
	"fmt"
	"time"
	"strings"
	"gorm.io/gorm"
	rCache "github.com/pywee/{{.path}}/cache"
	// "github.com/zeromicro/go-zero/core/stores/cache"
)
{{else}}
import "github.com/zeromicro/go-zero/core/stores/sqlx"
{{end}}
var _ {{.upperStartCamelObject}}Model = (*custom{{.upperStartCamelObject}}Model)(nil)

// 2024.04.18 修改
// 2024.05.14 修改 
type (
	{{.upperStartCamelObject}}Model interface {
		Get(context.Context, int64) (*{{.upperStartCamelObject}}, error)
		GetByWhere(context.Context, string, ...any) (*{{.upperStartCamelObject}}, error)
		GetByWhereNoCache(context.Context, string, ...any) (*{{.upperStartCamelObject}}, error)
		GetListByWhere(context.Context, string, ...any) ([]*{{.upperStartCamelObject}}, int64)
		GetListByWhereNoCache(context.Context, string, ...any) ([]*{{.upperStartCamelObject}}, int64)
		GetWithFields(context.Context, string, int64) (*{{.upperStartCamelObject}}, error)
		GetByWhereWithFields(context.Context, string, string, ...any) (*{{.upperStartCamelObject}}, error)
		GetByWhereWithFieldsNoCache(string, string, ...any) (*{{.upperStartCamelObject}}, error)
		GetListByWhereWithFields(context.Context, string, string, ...any) ([]*{{.upperStartCamelObject}}, int64)
		Insert(context.Context, *{{.upperStartCamelObject}}) (int64, error)
		Delete(context.Context, int64) (int64, error)
		HardDelete(context.Context, int64) error
		DeleteByWhere(context.Context, string, ...any) (int64, error)
		Update(context.Context, *{{.upperStartCamelObject}}) error
		UpdateByWhere(context.Context, map[string]any, string, ...any) (int64, error)
		Count(string, ...any) int64
		Sum(string, string, ...any) int64
	}

	custom{{.upperStartCamelObject}}Model struct {
		*customBaseModel
	}

	{{.upperStartCamelObject}}Resp struct {
		Count int64 `json:"c"`
		Resp  []*{{.upperStartCamelObject}} `json:"resp"`
	}
)

// New{{.upperStartCamelObject}}Model returns a model for the database table.
func New{{.upperStartCamelObject}}Model(conn *gorm.DB{{if .withCache}}, rds *rCache.RedisClientModel{{end}}) {{.upperStartCamelObject}}Model {
	return &custom{{.upperStartCamelObject}}Model{
		customBaseModel: &customBaseModel{
			c:     conn,
			rds:   rds,
			table: "{{.lowerStartCamelObject}}",
		},
	}
}

// Get 根据 ID 获取一条
func (m *custom{{.upperStartCamelObject}}Model) Get(ctx context.Context, id int64) (*{{.upperStartCamelObject}}, error) {
	return m.GetWithFields(ctx, "*", id)
}

// GetByWhere 根据条件获取一条记录
func (m *custom{{.upperStartCamelObject}}Model) GetByWhere(ctx context.Context, where string, args ...any) (*{{.upperStartCamelObject}}, error) {
	return m.GetByWhereWithFields(ctx, "*", where, args...)
}

// GetListByWhere 根据条件获取多条记录
func (m *custom{{.upperStartCamelObject}}Model) GetListByWhere(ctx context.Context, where string, args ...any) ([]*{{.upperStartCamelObject}}, int64) {
	return m.GetListByWhereWithFields(ctx, "*", where, args...)
}

func (m *custom{{.upperStartCamelObject}}Model) GetListByWhereNoCache(ctx context.Context, where string, args ...any) ([]*{{.upperStartCamelObject}}, int64) {
	var ret []*{{.upperStartCamelObject}}
	query := fmt.Sprintf("select * from `%s` %s", m.table, toSQLWhere(where, ""))
	if err := m.c.Raw(query, args...).Scan(&ret).Error; err != nil {
		return nil, 0
	}

	// 此处会潜在 bug，因为如果查询语句比较复杂，可能会出错
	if idx := strings.Index(where, "order by "); idx != -1 {
		where = where[:idx]
	} else if idx := strings.Index(where, "limit "); idx != -1 {
		where = where[:idx]
	}

	return ret, m.Count(where, args...)
}

// GetByWhere 根据条件获取一条记录
func (m *custom{{.upperStartCamelObject}}Model) GetByWhereNoCache(ctx context.Context, where string, args ...any) (*{{.upperStartCamelObject}}, error) {
	var resp {{.upperStartCamelObject}}
	query := fmt.Sprintf("select * from `%s` %s", m.table, toSQLWhere(where, "1"))
	if err := m.c.Raw(query, args...).Scan(&resp).Error; err != nil {
		return nil, err
	}
	if resp.Id == 0 {
		return nil, nil
	}

	return &resp, nil
}

// GetWithFields 根据 ID 获取一条记录
// 可选要获取的字段
func (m *custom{{.upperStartCamelObject}}Model) GetWithFields(ctx context.Context, fields string, id int64) (*{{.upperStartCamelObject}}, error) {
	var resp {{.upperStartCamelObject}}
	if fields == "" {
		fields = "*"
	}

	pctx := parseContext(ctx)
	key := fmt.Sprintf("model:site:%s:%s:id:%d", pctx.Domain, m.table, id)
	if ok, _ := m.rds.GetCache(key, &resp); ok {
		if resp.Id == 0 {
			return nil, NotFoundRecord
		}
		return &resp, nil
	}
	
	query := fmt.Sprintf("select %s from `%s` where id=? AND deleteTs=0", fields, m.table)
	if err := m.c.Raw(query, id).Scan(&resp).Error; err != nil {
		return nil, err
	}

	if resp.Id == 0 {
		m.rds.SetCache(key, resp, time.Second*2)
		return nil, NotFoundRecord
	}

	if pctx.DataCacheTTL > 0 {
		m.rds.SetCache(key, resp, time.Duration(pctx.DataCacheTTL)*time.Second)
	} else {
		m.rds.SetCache(key, resp, m.rds.TimeOut)
	}
	return &resp, nil
}

// GetByWhereWithFieldsNoCache
func (m *custom{{.upperStartCamelObject}}Model) GetByWhereWithFieldsNoCache(fields, where string, args ...any) (*{{.upperStartCamelObject}}, error) {
	if fields == "" {
		fields = "*"
	}

	var resp {{.upperStartCamelObject}}
	query := fmt.Sprintf("select %s from `%s` %s", fields, m.table, toSQLWhere(where, "1"))
	if err := m.c.Raw(query, args...).Scan(&resp).Error; err != nil {
		return nil, err
	}

	if resp.Id == 0 {
		return nil, nil
	}
	return &resp, nil
}

// GetByWhere 根据条件获取一条记录
// 可选要获取的字段
func (m *custom{{.upperStartCamelObject}}Model) GetByWhereWithFields(ctx context.Context, fields, where string, args ...any) (*{{.upperStartCamelObject}}, error) {
	if fields == "" {
		fields = "*"
	}

	var resp {{.upperStartCamelObject}}
	pctx := parseContext(ctx)
	query := fmt.Sprintf("select %s from `%s` %s", fields, m.table, toSQLWhere(where, "1"))
	key := fmt.Sprintf("model:site:%s:%s:get:%s", pctx.Domain, m.table, Md5(fmt.Sprintf("%s%v", query, args)))
	if ok, _ := m.rds.GetCache(key, &resp); ok {
		if resp.Id == 0 {
			return nil, nil
		}
		return &resp, nil
	}

	if err := m.c.Raw(query, args...).Scan(&resp).Error; err != nil {
		return nil, err
	}

	if resp.Id == 0 {
		m.rds.SetCache(key, resp, time.Second*2)
		return nil, nil
	}

	if pctx.DataCacheTTL > 0 {
		m.rds.SetCache(key, resp, time.Duration(pctx.DataCacheTTL)*time.Second)
	} else {
		m.rds.SetCache(key, resp, m.rds.TimeOut)
	}

	return &resp, nil
}

// GetListByWhereWithFields 根据条件获取多条记录
// 可选要获取的字段
func (m *custom{{.upperStartCamelObject}}Model) GetListByWhereWithFields(ctx context.Context, fields, where string, args ...any) ([]*{{.upperStartCamelObject}}, int64) {
	if fields == "" {
		fields = "*"
	}

	var ret {{.upperStartCamelObject}}Resp
	pctx := parseContext(ctx)
	query := fmt.Sprintf("select %s from `%s` %s", fields, m.table, toSQLWhere(where, ""))
	key := fmt.Sprintf("model:site:%s:%s:list:%s", pctx.Domain, m.table, Md5(fmt.Sprintf("%s%v", query, args)))
	if ok, _ := m.rds.GetCache(key, &ret); ok {
		return ret.Resp, ret.Count
	}

	if err := m.c.Raw(query, args...).Scan(&ret.Resp).Error; err != nil {
		return nil, 0
	}

	// 此处会潜在 bug，因为如果查询语句比较复杂，可能会出错
	if idx := strings.Index(where, "order by "); idx != -1 {
		where = where[:idx]
	} else if idx := strings.Index(where, "limit "); idx != -1 {
		where = where[:idx]
	}
	ret.Count = m.Count(where, args...)

	if pctx.DataCacheTTL > 0 {
		m.rds.SetCache(key, ret, time.Duration(pctx.DataCacheTTL)*time.Second)
	} else {
		m.rds.SetCache(key, ret, m.rds.TimeOut)
	}

	return ret.Resp, ret.Count
}

// Insert 新增
func (m *custom{{.upperStartCamelObject}}Model) Insert(ctx context.Context, data *{{.upperStartCamelObject}}) (int64, error) {
	if data.CreateTs == 0 {
		data.CreateTs = time.Now().Unix()
	}
	if data.UpdateTs == 0 {
		data.UpdateTs = data.CreateTs
	}

	ret := m.c.Table(m.table).Create(data)

	key := fmt.Sprintf("model:site:%s:%s:list:*", parseContext(ctx).Domain, m.table)
	m.rds.DelCache(key)

	return data.Id, ret.Error
}

// Update 更新单条记录
func (m *custom{{.upperStartCamelObject}}Model) Update(ctx context.Context, data *{{.upperStartCamelObject}}) error {
	data.UpdateTs = time.Now().Unix()
	ret := m.c.Table(m.table).Save(data)
	if ret.Error != nil {
		return ret.Error
	}

	key := fmt.Sprintf("model:site:%s:%s:*", parseContext(ctx).Domain, m.table)
	m.rds.DelCache(key)

	return nil
}