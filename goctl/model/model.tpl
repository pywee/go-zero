package {{.pkg}}
{{if .withCache}}
import (
	"context"
	"fmt"
	"time"
	"strings"
	"gorm.io/gorm"
	"github.com/zeromicro/go-zero/core/stores/cache"
)
{{else}}
import "github.com/zeromicro/go-zero/core/stores/sqlx"
{{end}}
var _ {{.upperStartCamelObject}}Model = (*custom{{.upperStartCamelObject}}Model)(nil)

// 2024.04.18 修改
type (
	{{.upperStartCamelObject}}Model interface {
		Insert(context.Context, *{{.upperStartCamelObject}}) (int64, error)
		Update(context.Context, *{{.upperStartCamelObject}}) error
		DeleteByID(context.Context, int64) (int64, error)
		Updates(context.Context, map[string]any, string, ...any) (int64, error)
		DeleteMany(context.Context, string, ...any) (int64, error)
		Get{{.upperStartCamelObject}}ById(context.Context, string, int64) (*{{.upperStartCamelObject}}, error)
		Get{{.upperStartCamelObject}}ByWhere(context.Context, string, string, ...any) (*{{.upperStartCamelObject}}, error)
		Count{{.upperStartCamelObject}}ByWhere(context.Context, string, ...any) (int64, error)
		Sum{{.upperStartCamelObject}}ByWhere(context.Context, string, string, ...any) (int64, error)
		Get{{.upperStartCamelObject}}ByWhereList(context.Context, string, string, ...any) ([]*{{.upperStartCamelObject}}, error)
	}

	custom{{.upperStartCamelObject}}Model struct {
		table string
		c *gorm.DB
	}
)

// New{{.upperStartCamelObject}}Model returns a model for the database table.
func New{{.upperStartCamelObject}}Model(conn *gorm.DB{{if .withCache}}, c cache.CacheConf, opts ...cache.Option{{end}}) {{.upperStartCamelObject}}Model {
	return &custom{{.upperStartCamelObject}}Model{
		c: conn,
		table: "{{.lowerStartCamelObject}}",
	}
}

// Get{{.upperStartCamelObject}}ByID 根据ID获取一条
func (m *custom{{.upperStartCamelObject}}Model) Get{{.upperStartCamelObject}}ById(ctx context.Context, fields string, id int64) (*{{.upperStartCamelObject}}, error) {
	var resp {{.upperStartCamelObject}}
	if fields == "" {
		fields = "*"
	}
	query := fmt.Sprintf("select %s from `%s` where id=? AND deleteTs=0", fields, m.table)
	if err := m.c.Raw(query, id).Scan(&resp).Error; err != nil {
		return nil, err
	}
	if resp.Id == 0 {
		return nil, nil
	}
	return &resp, nil
}

// Get{{.upperStartCamelObject}}ByID 根据条件获取一条
func (m *custom{{.upperStartCamelObject}}Model) Get{{.upperStartCamelObject}}ByWhere(ctx context.Context, fields, where string, args ...any) (*{{.upperStartCamelObject}}, error) {
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
	if !strings.Contains(where, strings.ToLower("limit ")) {
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

// Get{{.upperStartCamelObject}}ByID 根据条件获取多条记录
func (m *custom{{.upperStartCamelObject}}Model) Get{{.upperStartCamelObject}}ByWhereList(ctx context.Context, fields, where string, args ...any) ([]*{{.upperStartCamelObject}}, error) {
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
func (m *custom{{.upperStartCamelObject}}Model) Count{{.upperStartCamelObject}}ByWhere(ctx context.Context, where string, args ...any) (int64, error) {
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
func (m *custom{{.upperStartCamelObject}}Model) Sum{{.upperStartCamelObject}}ByWhere(ctx context.Context, sumField, where string, args ...any) (int64, error) {
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
func (m *custom{{.upperStartCamelObject}}Model) Insert(ctx context.Context, data *{{.upperStartCamelObject}}) (int64, error) {
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
func (m *custom{{.upperStartCamelObject}}Model) Update(ctx context.Context, data *{{.upperStartCamelObject}}) error {
	if data.UpdateTs == 0 {
		data.UpdateTs = time.Now().Unix()
	}
	ret := m.c.Table(m.table).Save(data)
	return ret.Error
}

// UpdateMap 根据条件批量更新
func (m *custom{{.upperStartCamelObject}}Model) Updates(ctx context.Context, data map[string]any, where string, args ...any) (int64, error) {
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
func (m *custom{{.upperStartCamelObject}}Model) DeleteByID(ctx context.Context, ID int64) (int64, error) {
	ts := time.Now().Unix()
	ret := m.c.Exec("UPDATE `" + m.table + "` SET deleteTs=?,updateTs=? WHERE id=?", ts, ts, ID)
	return ret.RowsAffected, ret.Error
}

// DeleteMany 根据条件批量删除
func (m *custom{{.upperStartCamelObject}}Model) DeleteMany(ctx context.Context, where string, args ...any) (int64, error) {
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