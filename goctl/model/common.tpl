package model

import (
	"reflect"
	"strconv"
	"strings"

	rCache "github.com/pywee/fangzhoucms/cache"
	"github.com/zeromicro/go-zero/core/stores/cache"
	"gorm.io/gorm"
)

type (
	BaseModel interface {
		Query(map[string]any, string, ...any) error
		QueryList(string, ...any) ([]map[string]string, error)
	}
	customBaseModel struct {
		c   *gorm.DB
		rds *rCache.RedisClientModel
	}
)

func NewBaseModel(conn *gorm.DB, rds *rCache.RedisClientModel, opts ...cache.Option) BaseModel {
	return &customBaseModel{
		c:   conn,
		rds: rds,
	}
}

// Query 原生查询语句
func (b *customBaseModel) Query(ret map[string]any, sql string, args ...any) error {
	m := b.c.Raw(sql, args...).First(&ret)
	return m.Error
}

// Query 原生查询语句
func (b *customBaseModel) QueryList(sql string, args ...any) ([]map[string]string, error) {
	rows, err := b.c.Raw(sql, args...).Rows()
	if err != nil {
		return nil, err
	}

	list := make([]map[string]string, 0, 5)
	columns, _ := rows.Columns()
	columnLength := len(columns)
	cache := make([]any, columnLength)
	for index := range cache {
		var a any
		cache[index] = &a
	}

	for rows.Next() {
		rows.Scan(cache...)
		item := make(map[string]string)
		for i, data := range cache {
			// fmt.Println(columns[i], reflect.TypeOf(v).String())
			item[columns[i]] = typeToString(*data.(*any))
		}
		list = append(list, item)
	}

	rows.Close()
	return list, nil
}

// toSQLWhere 转换为内部标准 WHERE 条件语句
// 如果 limit 为空则表示不限制
func toSQLWhere(where, limit string) string {
	if !strings.Contains(where, "deleteTs") {
		where = "where deleteTs=0 AND " + where
		where = strings.TrimSuffix(where, "AND ")
	} else if where != "" {
		where = "where " + where
	}
	if limit != "" && !strings.Contains(strings.ToLower(where), "limit ") {
		where += " LIMIT " + limit
	}

	return where
}

func typeToString(v any) string {
	value := reflect.ValueOf(v)
	vt := value.Type().String()
	switch vt {
	case "[]uint8":
		return string(value.Bytes())
	case "string":
		return value.String()
	case "int64", "int32", "int16", "int8", "int":
		return strconv.FormatInt(value.Int(), 10)
	case "uint64", "uint", "uint32", "uint16", "uint8", "byte":
		return strconv.FormatUint(value.Uint(), 10)
	case "float64", "float32":
		return strconv.FormatFloat(value.Float(), 'f', -1, 64)
	case "bool":
		if vb := value.Bool(); vb {
			return "true"
		}
		return "false"
	}
	return ""
}

// byte2Str []byte to string
//func byte2Str(b []byte) string {
//return *(*string)(unsafe.Pointer(&b))
//}

// // Exec 原生执行语句
// func Exec(sql string, args ...any) error {
// if err := c.Exec(sql, args...).Error; err != nil {
// return err
// }
// return nil
// }