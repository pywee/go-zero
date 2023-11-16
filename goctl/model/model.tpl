package {{.pkg}}
{{if .withCache}}
import (
	"context"
	"crypto/md5"
	"fmt"
	"github.com/zeromicro/go-zero/core/stores/cache"
	"github.com/zeromicro/go-zero/core/stores/sqlc"
	"github.com/zeromicro/go-zero/core/stores/sqlx"
)
{{else}}

import "github.com/zeromicro/go-zero/core/stores/sqlx"
{{end}}
var _ {{.upperStartCamelObject}}Model = (*custom{{.upperStartCamelObject}}Model)(nil)

type (
	// {{.upperStartCamelObject}}Model is an interface to be customized, add more methods here,
	// and implement the added methods in custom{{.upperStartCamelObject}}Model.
	{{.upperStartCamelObject}}Model interface {
		{{.lowerStartCamelObject}}Model
		Get{{.tableNameStr}}ByWhere(context.Context, string, ...any) (*{{.upperStartCamelObject}}, error)
		Get{{.tableNameStr}}ListByWhere(context.Context, string, ...any) ([]*{{.upperStartCamelObject}}, error)
		Sum{{.tableNameStr}}ByWhere(context.Context, string, string, ...any) (int64, error)
	}

	custom{{.upperStartCamelObject}}Model struct {
		*default{{.upperStartCamelObject}}Model
	}
)

// New{{.upperStartCamelObject}}Model returns a model for the database table.
func New{{.upperStartCamelObject}}Model(conn sqlx.SqlConn{{if .withCache}}, c cache.CacheConf, opts ...cache.Option{{end}}) {{.upperStartCamelObject}}Model {
	return &custom{{.upperStartCamelObject}}Model{
		default{{.upperStartCamelObject}}Model: new{{.upperStartCamelObject}}Model(conn{{if .withCache}}, c, opts...{{end}}),
	}
}

// Sum{{.tableNameStr}}ByWhere 根据条件统计数量
func (m *default{{.upperStartCamelObject}}Model) Sum{{.tableNameStr}}ByWhere(ctx context.Context, field, where string, args ...any) (int64, error) {
	kk := where
	for _, v := range args {
		kk += fmt.Sprintf("%v", v)
	}

	// key := fmt.Sprintf("%x", md5.Sum([]byte(kk)))
	// bluettiPointsRecordIdKey := fmt.Sprintf("%s%s", cacheBluettiPointsRecordIdPrefix, key)
	// _ = bluettiPointsRecordIdKey

	resp := struct { C int64 }{}
	query := fmt.Sprintf("select sum(%s) C from %s", field, m.table)
	if where != "" {
		query = fmt.Sprintf("select sum(%s) C from %s where %s", field, m.table, where)
	}
	err := m.QueryRowNoCacheCtx(ctx, &resp, query, args...)

	if err != nil {
		if err == sqlc.ErrNotFound {
			return 0, ErrNotFound
		}
		return 0, err
	}
	return resp.C, nil
}

// Get{{.tableNameStr}}ByWhere 根据条件获取列表数据
func (m *default{{.upperStartCamelObject}}Model) Get{{.tableNameStr}}ByWhere(ctx context.Context, where string, args ...any) (*{{.upperStartCamelObject}}, error) {
	kk := where
	for _, v := range args {
		kk += fmt.Sprintf("%v", v)
	}

	var resp PointsRecord
	query := fmt.Sprintf("select %s from %s LIMIT 1", pointsRecordRows, m.table)
	if where != "" {
		query = fmt.Sprintf("select %s from %s where %s LIMIT 1", pointsRecordRows, m.table, where)
	}
	err := m.QueryRowsNoCacheCtx(ctx, &resp, query, args...)

	if err != nil {
		if err == sqlc.ErrNotFound {
			return nil, ErrNotFound
		}
		return nil, err
	}
	return &resp, nil
}

// Get{{.tableNameStr}}ListByWhere 根据条件获取列表数据
func (m *default{{.upperStartCamelObject}}Model) Get{{.tableNameStr}}ListByWhere(ctx context.Context, where string, args ...any) ([]*{{.upperStartCamelObject}}, error) {
	kk := where
	for _, v := range args {
		kk += fmt.Sprintf("%v", v)
	}

	key := fmt.Sprintf("%x", md5.Sum([]byte(kk)))
	bluettiPointsRecordIdKey := fmt.Sprintf("%s%s", cacheBluettiPointsRecordIdPrefix, key)
	_ = bluettiPointsRecordIdKey

	var resp []*PointsRecord
	query := fmt.Sprintf("select %s from %s", pointsRecordRows, m.table)
	if where != "" {
		query = fmt.Sprintf("select %s from %s where %s", pointsRecordRows, m.table, where)
	}
	err := m.QueryRowsNoCacheCtx(ctx, &resp, query, args...)

	if err != nil {
		if err == sqlc.ErrNotFound {
			return nil, ErrNotFound
		}
		return nil, err
	}
	return resp, nil
}