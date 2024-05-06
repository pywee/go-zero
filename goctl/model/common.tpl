package model

import (
	"context"
	"fmt"
	"strings"
)


// GetByID 根据 ID 获取一条记录
func (m *customOrderModel) GetByID(resp any, id int64, fields string) error {
	if fields == "" {
		fields = "*"
	}
	query := fmt.Sprintf("select %s from `%s` where id=? AND deleteTs=0", fields, m.table)
	if err := m.c.Raw(query, id).Scan(resp).Error; err != nil {
		return err
	}
	return nil
}

// GetByWhere 根据条件获取一条记录
func (m *customOrderModel) GetByWhere(ctx context.Context, resp any, fields, where string, args ...any) error {
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
	if err := m.c.Raw(query, args...).Scan(resp).Error; err != nil {
		return err
	}
	return nil
}