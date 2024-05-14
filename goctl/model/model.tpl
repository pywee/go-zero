package {{.pkg}}
{{if .withCache}}
import (
	"fmt"
	"time"
	"strings"
	"gorm.io/gorm"
	rCache "github.com/pywee/mw/cache"
	"github.com/zeromicro/go-zero/core/stores/cache"
)
{{else}}
import "github.com/zeromicro/go-zero/core/stores/sqlx"
{{end}}
var _ {{.upperStartCamelObject}}Model = (*custom{{.upperStartCamelObject}}Model)(nil)

// 2024.04.18 修改
// 2024.05.14 修改
type (
	{{.upperStartCamelObject}}Model interface {
		Insert(*{{.upperStartCamelObject}}) (int64, error)
		Delete(int64) (int64, error)
		DeleteByWhere(string, ...any) (int64, error)
		Update(*{{.upperStartCamelObject}}) error
		UpdateByWhere(map[string]any, string, ...any) (int64, error)
		Get(string, int64) (*{{.upperStartCamelObject}}, error)
		GetByWhere(string, string, ...any) (*{{.upperStartCamelObject}}, error)
		GetListByWhere(string, string, ...any) ([]*{{.upperStartCamelObject}}, error)
		Count(string, ...any) (int64, error)
		Sum(string, string, ...any) (int64, error)
	}

	custom{{.upperStartCamelObject}}Model struct {
		table string
		c *gorm.DB
		rds *rCache.RedisClientModel
	}
)

// New{{.upperStartCamelObject}}Model returns a model for the database table.
func New{{.upperStartCamelObject}}Model(conn *gorm.DB{{if .withCache}}, rds *rCache.RedisClientModel, opts ...cache.Option{{end}}) {{.upperStartCamelObject}}Model {
	return &custom{{.upperStartCamelObject}}Model{
		c: conn,
		rds:   rds,
		table: "{{.lowerStartCamelObject}}",
	}
}

// Get 根据 ID 获取一条
func (m *custom{{.upperStartCamelObject}}Model) Get(fields string, id int64) (*{{.upperStartCamelObject}}, error) {
	var resp {{.upperStartCamelObject}}
	var fk = "allFields"
	if fields == "" {
		fields = "*"
	} else {
		fk = strings.Replace(fields, ",", "", -1)
	}
	key := fmt.Sprintf("model:table:%s:cache:id:%d:fields:%s", m.table, id, fk)
	if ok, _ := m.rds.GetCache(key, &resp); ok {
		return &resp, nil
	}
	
	query := fmt.Sprintf("select %s from `%s` where id=? AND deleteTs=0", fields, m.table)
	if err := m.c.Raw(query, id).Scan(&resp).Error; err != nil {
		return nil, err
	}
	if resp.Id == 0 {
		return nil, NotFoundRecord
	}
	_ = m.rds.SetCache(key, resp, time.Hour)
	return &resp, nil
}

// GetByWhere 根据条件获取一条记录
func (m *custom{{.upperStartCamelObject}}Model) GetByWhere(fields, where string, args ...any) (*{{.upperStartCamelObject}}, error) {
	var resp {{.upperStartCamelObject}}
	if fields == "" {
		fields = "*"
	}
	if !strings.Contains(where, "deleteTs") {
		where = "where deleteTs=0 AND " + where
		where = strings.TrimSuffix(where, "AND ")
	} else if where != "" {
		where = "where " + where
	}
	if !strings.Contains(strings.ToLower(where), "limit ") {
		where += " LIMIT 1"
	}

	query := fmt.Sprintf("select %s from `%s` %s", fields, m.table, where)
	if err := m.c.Raw(query, args...).Scan(&resp).Error; err != nil {
		return nil, err
	}
	if resp.Id == 0 {
		return nil, nil
	}
	return &resp, nil
}

// GetListByWhere 根据条件获取多条记录
func (m *custom{{.upperStartCamelObject}}Model) GetListByWhere(fields, where string, args ...any) ([]*{{.upperStartCamelObject}}, error) {
	var resp []*{{.upperStartCamelObject}}
	if fields == "" {
		fields = "*"
	}
	if !strings.Contains(where, "deleteTs") {
		where = "where deleteTs=0 AND " + where
		where = strings.TrimSuffix(where, "AND ")
	} else if where != "" {
		where = "where " + where
	}

	query := fmt.Sprintf("select %s from `%s` %s", fields, m.table, where)
	if err := m.c.Raw(query, args...).Scan(&resp).Error; err != nil {
		return nil, err
	}
	return resp, nil
}

// CountByWhere 根据条件计数
func (m *custom{{.upperStartCamelObject}}Model) Count(where string, args ...any) (int64, error) {
	var resp struct {
		C int64 `gorm:"column:c" json:"c"`
	}

	if !strings.Contains(where, "deleteTs") {
		where = "where deleteTs=0 AND " + where
		where = strings.TrimSuffix(where, "AND ")
	} else if where != "" {
		where = "where " + where
	}

	query := fmt.Sprintf("select count(*) c from `%s` %s", m.table, where)
	err := m.c.Raw(query, args...).Scan(&resp).Error
	return resp.C, err
}

// CountByWhere 根据条件统计多条记录
func (m *custom{{.upperStartCamelObject}}Model) Sum(sumField, where string, args ...any) (int64, error) {
	var resp struct {
		S int64 `gorm:"column:s" json:"s"`
	}

	if !strings.Contains(where, "deleteTs") {
		where = "where deleteTs=0 AND " + where
		where = strings.TrimSuffix(where, "AND ")
	} else if where != "" {
		where = "where " + where
	}

	query := fmt.Sprintf("select sum(%s) s from `%s` %s", sumField, m.table, where)
	err := m.c.Raw(query, args...).Scan(&resp).Error
	return resp.S, err
}

// Insert 新增
func (m *custom{{.upperStartCamelObject}}Model) Insert(data *{{.upperStartCamelObject}}) (int64, error) {
	if data.CreateTs == 0 {
		ts := time.Now().Unix()
		data.CreateTs = ts
		data.UpdateTs = ts
	}

	ret := m.c.Table(m.table).Create(data)
	// return ret.RowsAffected, nil
	return data.Id, ret.Error
}

// Update 更新单条记录
func (m *custom{{.upperStartCamelObject}}Model) Update(data *{{.upperStartCamelObject}}) error {
	if data.UpdateTs == 0 {
		data.UpdateTs = time.Now().Unix()
	}
	ret := m.c.Table(m.table).Save(data)
	if ret.Error != nil {
		return ret.Error
	}
	m.rds.DelCache(fmt.Sprintf("model:table:%s:cache:id:%d:fields:*", m.table, data.Id))
	return nil
}

// UpdateByWhere 根据条件批量更新
func (m *custom{{.upperStartCamelObject}}Model) UpdateByWhere(data map[string]any, where string, args ...any) (int64, error) {
	if _, ok := data["updateTs"]; !ok {
		data["updateTs"] = time.Now().Unix()
	}
	ret := m.c.Table(m.table).Where(where, args...).Updates(data)
	return ret.RowsAffected, ret.Error
}

// Delete 根据 ID 删除记录
func (m *custom{{.upperStartCamelObject}}Model) Delete(ID int64) (int64, error) {
	ts := time.Now().Unix()
	ret := m.c.Exec("UPDATE `" + m.table + "` SET deleteTs=?,updateTs=? WHERE id=?", ts, ts, ID)
	m.rds.DelCache(fmt.Sprintf("model:table:%s:cache:id:%d:fields:*", m.table, ID))
	return ret.RowsAffected, ret.Error
}

// DeleteByWhere 根据条件批量删除
func (m *custom{{.upperStartCamelObject}}Model) DeleteByWhere(where string, args ...any) (int64, error) {
	ts := time.Now().Unix()
	ret := m.c.Table(m.table).Where(where, args...).Updates(map[string]any{
		"updateTs": ts,
		"deleteTs": ts,
	})
	return ret.RowsAffected, ret.Error
}