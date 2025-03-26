package {{.pkg}}
{{if .withCache}}
import (
	"fmt"
	"time"
	"strings"
	"gorm.io/gorm"
	rCache "github.com/pywee/fangzhoucms/cache"
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
		Get(int64) (*{{.upperStartCamelObject}}, error)
		GetByWhere(string, ...any) (*{{.upperStartCamelObject}}, error)
		GetListByWhere(string, ...any) ([]*{{.upperStartCamelObject}}, int64)
		GetWithFields(string, int64) (*{{.upperStartCamelObject}}, error)
		GetByWhereWithFields(string, string, ...any) (*{{.upperStartCamelObject}}, error)
		GetListByWhereWithFields(string, string, ...any) ([]*{{.upperStartCamelObject}}, int64)
		Count(string, ...any) (int64, error)
		Sum(string, string, ...any) (int64, error)
		Insert(*{{.upperStartCamelObject}}) (int64, error)
		Delete(int64) (int64, error)
		HardDelete(int64) error
		DeleteByWhere(string, ...any) (int64, error)
		Update(*{{.upperStartCamelObject}}) error
		UpdateByWhere(map[string]any, string, ...any) (int64, error)
	}

	custom{{.upperStartCamelObject}}Model struct {
		table string
		c *gorm.DB
		cacheKey string
		rds *rCache.RedisClientModel
	}

	{{.upperStartCamelObject}}Resp struct {
		Count int64 `json:"c"`
		Resp  []*{{.upperStartCamelObject}} `json:"resp"`
	}
)

// New{{.upperStartCamelObject}}Model returns a model for the database table.
func New{{.upperStartCamelObject}}Model(conn *gorm.DB{{if .withCache}}, rds *rCache.RedisClientModel{{end}}) {{.upperStartCamelObject}}Model {
	return &custom{{.upperStartCamelObject}}Model{
		c: conn,
		rds: rds,
		table: "{{.lowerStartCamelObject}}",
		cacheKey: "model:%s:id:%d",
	}
}

// Get 根据 ID 获取一条
func (m *custom{{.upperStartCamelObject}}Model) Get(id int64) (*{{.upperStartCamelObject}}, error) {
	return m.GetWithFields("*", id)
}

// GetByWhere 根据条件获取一条记录
func (m *custom{{.upperStartCamelObject}}Model) GetByWhere(where string, args ...any) (*{{.upperStartCamelObject}}, error) {
	return m.GetByWhereWithFields("*", where, args...)
}

// GetListByWhere 根据条件获取多条记录
func (m *custom{{.upperStartCamelObject}}Model) GetListByWhere(where string, args ...any) ([]*{{.upperStartCamelObject}}, int64) {
	return m.GetListByWhereWithFields("*", where, args...)
}

// Get 根据 ID 获取一条记录
// 可选要获取的字段
func (m *custom{{.upperStartCamelObject}}Model) GetWithFields(fields string, id int64) (*{{.upperStartCamelObject}}, error) {
	var resp {{.upperStartCamelObject}}
	if fields == "" {
		fields = "*"
	}

	key := fmt.Sprintf(m.cacheKey, m.table, id)
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
		m.rds.SetCache(key, resp, time.Minute)
		return nil, NotFoundRecord
	}

	m.rds.SetCache(key, resp, m.rds.TimeOut)

	return &resp, nil
}

// GetByWhere 根据条件获取一条记录
// 可选要获取的字段
func (m *custom{{.upperStartCamelObject}}Model) GetByWhereWithFields(fields, where string, args ...any) (*{{.upperStartCamelObject}}, error) {
	if fields == "" {
		fields = "*"
	}

	var resp {{.upperStartCamelObject}}
	query := fmt.Sprintf("select %s from `%s` %s", fields, m.table, toSQLWhere(where, "1"))
	key := "model:" + m.table + ":where:get:" + Md5(fmt.Sprintf("%s%v", query, args))
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
		m.rds.SetCache(key, resp, time.Minute)
		return nil, nil
	}
	m.rds.SetCache(key, resp, m.rds.TimeOut)

	return &resp, nil
}

// GetListByWhereWithFields 根据条件获取多条记录
// 可选要获取的字段
func (m *custom{{.upperStartCamelObject}}Model) GetListByWhereWithFields(fields, where string, args ...any) ([]*{{.upperStartCamelObject}}, int64) {
	if fields == "" {
		fields = "*"
	}

	var ret {{.upperStartCamelObject}}Resp
	query := fmt.Sprintf("select %s from `%s` %s", fields, m.table, toSQLWhere(where, ""))
	key := "model:" + m.table + ":where:list:" + Md5(fmt.Sprintf("%s%v", query, args))
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
	ret.Count, _ = m.Count(where, args...)
	m.rds.SetCache(key, ret, m.rds.TimeOut)

	return ret.Resp, ret.Count
}

// CountByWhere 根据条件计数
func (m *custom{{.upperStartCamelObject}}Model) Count(where string, args ...any) (int64, error) {
	var resp struct {
		C int64 `gorm:"column:c" json:"c"`
	}

	query := fmt.Sprintf("select count(*) c from `%s` %s", m.table, toSQLWhere(where, ""))
	err := m.c.Raw(query, args...).Scan(&resp).Error
	return resp.C, err
}

// CountByWhere 根据条件统计多条记录
func (m *custom{{.upperStartCamelObject}}Model) Sum(sumField, where string, args ...any) (int64, error) {
	var resp struct {
		S int64 `gorm:"column:s" json:"s"`
	}

	query := fmt.Sprintf("select sum(%s) s from `%s` %s", sumField, m.table, toSQLWhere(where, ""))
	err := m.c.Raw(query, args...).Scan(&resp).Error
	return resp.S, err
}

// Insert 新增
func (m *custom{{.upperStartCamelObject}}Model) Insert(data *{{.upperStartCamelObject}}) (int64, error) {
	ts := time.Now().Unix()
	if data.CreateTs == 0 {
		data.CreateTs = ts
	}
	if data.UpdateTs == 0 {
		data.UpdateTs = ts
	}

	ret := m.c.Table(m.table).Create(data)
	m.rds.DelCache("model:" + m.table + ":where:list:*")
	// return ret.RowsAffected, nil
	return data.Id, ret.Error
}

// Update 更新单条记录
func (m *custom{{.upperStartCamelObject}}Model) Update(data *{{.upperStartCamelObject}}) error {
	data.UpdateTs = time.Now().Unix()
	ret := m.c.Table(m.table).Save(data)
	if ret.Error != nil {
		return ret.Error
	}

	// m.rds.DelCache(fmt.Sprintf(m.cacheKey, m.table, data.Id))
	m.rds.DelCache("model:" + m.table + ":*")

	return nil
}

// UpdateByWhere 根据条件批量更新
func (m *custom{{.upperStartCamelObject}}Model) UpdateByWhere(data map[string]any, where string, args ...any) (int64, error) {
	if _, ok := data["updateTs"]; !ok {
		data["updateTs"] = time.Now().Unix()
	}
	ret := m.c.Table(m.table).Where(where, args...).Updates(data)
	m.rds.DelCache("model:" + m.table + ":*")
	return ret.RowsAffected, ret.Error
}

// Delete 根据 ID 删除记录
func (m *custom{{.upperStartCamelObject}}Model) Delete(ID int64) (int64, error) {
	ts := time.Now().Unix()
	ret := m.c.Exec("UPDATE `" + m.table + "` SET deleteTs=?,updateTs=? WHERE id=?", ts, ts, ID)
	// m.rds.DelCache(fmt.Sprintf(m.cacheKey, m.table, ID))
	m.rds.DelCache("model:" + m.table + ":*")
	return ret.RowsAffected, ret.Error
}

// DeleteByWhere 根据条件批量删除
func (m *custom{{.upperStartCamelObject}}Model) DeleteByWhere(where string, args ...any) (int64, error) {
	ts := time.Now().Unix()
	ret := m.c.Table(m.table).Where(where, args...).Updates(map[string]any{
		"updateTs": ts,
		"deleteTs": ts,
	})
	m.rds.DelCache("model:" + m.table + ":*")
	return ret.RowsAffected, ret.Error
}

// HardDelete 硬删除操作
func (m *custom{{.upperStartCamelObject}}Model) HardDelete(ID int64) error {
	ret := m.c.Exec("DELETE FROM `"+m.table+"` WHERE id=?", ID)
	m.rds.DelCache("model:" + m.table + ":*")
	return ret.Error
}