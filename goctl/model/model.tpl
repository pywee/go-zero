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
type (
	{{.upperStartCamelObject}}Model interface {
		Insert(*{{.upperStartCamelObject}}) (int64, error)
		Get{{.upperStartCamelObject}}ById(string, int64) (*{{.upperStartCamelObject}}, error)
		Get{{.upperStartCamelObject}}ByWhere(string, string, ...any) (*{{.upperStartCamelObject}}, error)
		Get{{.upperStartCamelObject}}ByWhereList(string, string, ...any) ([]*{{.upperStartCamelObject}}, error)
		Update(*{{.upperStartCamelObject}}) error
		Updates(map[string]any, string, ...any) (int64, error)
		Count{{.upperStartCamelObject}}ByWhere(string, ...any) (int64, error)
		Sum{{.upperStartCamelObject}}ByWhere(string, string, ...any) (int64, error)
		DeleteByID(int64) (int64, error)
		DeleteMany(string, ...any) (int64, error)
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

// Get{{.upperStartCamelObject}}ByID 根据ID获取一条
func (m *custom{{.upperStartCamelObject}}Model) Get{{.upperStartCamelObject}}ById(fields string, id int64) (*{{.upperStartCamelObject}}, error) {
	var resp {{.upperStartCamelObject}}
	key := fmt.Sprintf("model:table:%s:cache:id:%d", m.table, id)
	if ok, _ := m.rds.GetCache(key, &resp); ok {
		return &resp, nil
	}
	if fields == "" {
		fields = "*"
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

// Get{{.upperStartCamelObject}}ByWhere 根据条件获取一条记录
func (m *custom{{.upperStartCamelObject}}Model) Get{{.upperStartCamelObject}}ByWhere(fields, where string, args ...any) (*{{.upperStartCamelObject}}, error) {
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

// Get{{.upperStartCamelObject}}ByWhereList 根据条件获取多条记录
func (m *custom{{.upperStartCamelObject}}Model) Get{{.upperStartCamelObject}}ByWhereList(fields, where string, args ...any) ([]*{{.upperStartCamelObject}}, error) {
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

// Count{{.upperStartCamelObject}}ByWhere 根据条件计数
func (m *custom{{.upperStartCamelObject}}Model) Count{{.upperStartCamelObject}}ByWhere(where string, args ...any) (int64, error) {
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
	if err := m.c.Raw(query, args...).Scan(&resp).Error; err != nil {
		return 0, err
	}
	return resp.C, nil
}

// Count{{.upperStartCamelObject}}ByWhere 根据条件统计多条记录
func (m *custom{{.upperStartCamelObject}}Model) Sum{{.upperStartCamelObject}}ByWhere(sumField, where string, args ...any) (int64, error) {
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
	if err := m.c.Raw(query, args...).Scan(&resp).Error; err != nil {
		return 0, err
	}
	return resp.S, nil
}

// Insert 新增
func (m *custom{{.upperStartCamelObject}}Model) Insert(data *{{.upperStartCamelObject}}) (int64, error) {
	if data.CreateTs == 0 {
		ts := time.Now().Unix()
		data.CreateTs = ts
		data.UpdateTs = ts
	}

	ret := m.c.Table(m.table).Create(data)
	if err := ret.Error; err != nil {
		return 0, err
	}

	// return ret.RowsAffected, nil
	return data.Id, nil
}

// Update 更新
func (m *custom{{.upperStartCamelObject}}Model) Update(data *{{.upperStartCamelObject}}) error {
	if data.UpdateTs == 0 {
		data.UpdateTs = time.Now().Unix()
	}
	ret := m.c.Table(m.table).Save(data)
	if ret.Error != nil {
		return ret.Error
	}

	m.rds.DelCache(fmt.Sprintf("model:table:%s:cache:id:%d", m.table, data.Id))
	
	return nil
}

// UpdateMap 根据条件批量更新
func (m *custom{{.upperStartCamelObject}}Model) Updates(data map[string]any, where string, args ...any) (int64, error) {
	if _, ok := data["updateTs"]; !ok {
		data["updateTs"] = time.Now().Unix()
	}
	ret := m.c.Table(m.table).Where(where, args...).Updates(data)
	if err := ret.Error; err != nil {
		return 0, err
	}
	return ret.RowsAffected, nil
}

// DeleteByID 根据 ID 删除记录
func (m *custom{{.upperStartCamelObject}}Model) DeleteByID(ID int64) (int64, error) {
	ts := time.Now().Unix()
	ret := m.c.Exec("UPDATE `" + m.table + "` SET deleteTs=?,updateTs=? WHERE id=?", ts, ts, ID)
	m.rds.DelCache(fmt.Sprintf("model:table:%s:cache:id:%d", m.table, ID))
	return ret.RowsAffected, ret.Error
}

// DeleteMany 根据条件批量删除
func (m *custom{{.upperStartCamelObject}}Model) DeleteMany(where string, args ...any) (int64, error) {
	ts := time.Now().Unix()
	ret := m.c.Table(m.table).Where(where, args...).Updates(map[string]any{
		"updateTs": ts,
		"deleteTs": ts,
	})
	if err := ret.Error; err != nil {
		return 0, err
	}
	return ret.RowsAffected, nil
}