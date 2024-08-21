package model

import (
	"encoding/json"
	"errors"
	"reflect"
	"strconv"
	"strings"

	rCache "github.com/pywee/f/cache"
	"github.com/pywee/f/utils"
	"github.com/zeromicro/go-zero/core/logx"
	"github.com/zeromicro/go-zero/core/stores/cache"
	"gorm.io/gorm"
)

type (
	BaseModel interface {
		Query(map[string]string, string, ...any) error
		QueryList(string, ...any) ([]map[string]string, error)
		QueryFieldList(string, ...any) ([]string, error)
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
func (b *customBaseModel) Query(ret map[string]string, ql string, args ...any) error {
	if ret == nil {
		return errors.New("can not use a map of nil")
	}

	db, err := b.c.DB()
	if err != nil {
		return err
	}

	ckey := ""
	rdsCli := b.rds
	if rdsCli != nil {
		ckey = utils.Md5(ql)
		if r, _ := rdsCli.Get(ckey); r != "" {
			if err = json.Unmarshal([]byte(r), &ret); err == nil {
				return nil
			}
		}
	}

	rows, err := db.Query(ql, args...)
	if err != nil {
		return err
	}
	defer rows.Close()

	columns, _ := rows.Columns()
	cLen := len(columns)
	for rows.Next() {
		values := make([]any, cLen)
		valuePtrs := make([]any, cLen)
		for i := range values {
			valuePtrs[i] = &values[i]
		}
		if err := rows.Scan(valuePtrs...); err != nil {
			return err
		}
		for i := 0; i < cLen; i++ {
			ret[columns[i]] = typeToString(values[i])
		}
	}

	if rdsCli != nil {
		s, _ := json.Marshal(ret)
		if err = rdsCli.Set(ckey, s, rdsCli.TimeOut); err != nil {
			logx.Errorf("fail to set cache key: %s, sql: %s", ckey, ql)
		}
	}

	return nil
}

// Query 原生查询语句
func (b *customBaseModel) QueryList(ql string, args ...any) ([]map[string]string, error) {
	rows, err := b.c.Raw(ql, args...).Rows()
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

QueryFieldList 原生查询语句
// 对于查询单个字段的列表时有用
func (b *customBaseModel) QueryFieldList(ql string, args ...any) ([]string, error) {
	rows, err := b.c.Raw(ql, args...).Rows()
	if err != nil {
		return nil, err
	}

	list := make([]string, 0, 5)
	columns, _ := rows.Columns()
	columnLength := len(columns)
	cache := make([]any, columnLength)
	for index := range cache {
		var a any
		cache[index] = &a
	}

	for rows.Next() {
		rows.Scan(cache...)
		// item := make(map[string]string)
		for _, data := range cache {
			// fmt.Println(columns[i], reflect.TypeOf(v).String())
			// item[columns[i]] = typeToString(*data.(*any))
			list = append(list, typeToString(*data.(*any)))
		}
		// list = append(list, item)
	}

	rows.Close()
	return list, nil
}

// toSQLWhere 转换为内部标准 WHERE 条件语句
// 如果 limit 为空则表示不限制
func toSQLWhere(where, limit string) string {
	and := ""
	sw := strings.ToLower(strings.TrimSpace(where))
	if sw != "" && !strings.HasPrefix(sw, "order") && !strings.HasPrefix(sw, "limit") {
		and = " AND "
	}

	if !strings.Contains(where, "delete_ts") {
		where = "where delete_ts=0 " + and + where
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