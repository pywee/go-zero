package model

import (
	"time"
	"crypto/md5"
	"fmt"
	"context"
	"reflect"
	"strconv"
	"strings"

	rCache "github.com/pywee/fangzhoucms/cache"
	"github.com/pywee/fangzhoucms/utils"
	"github.com/zeromicro/go-zero/core/stores/cache"
	"gorm.io/gorm"
)

type (
	BaseModel interface {
		Exec(string, ...any) error
		QueryCache(context.Context, string, string, ...any) (map[string]string, error)
		QueryListCache(context.Context, string, string, ...any) ([]map[string]string, error)
		Query(string, ...any) (map[string]string, error)
		QueryList(string, ...any) ([]map[string]string, error)
		QueryFieldList(string, ...any) ([]string, error)
	}
	customBaseModel struct {
		c   *gorm.DB
		rds *rCache.RedisClientModel
	}
)

func NewBaseModel(conn *gorm.DB,rds *rCache.RedisClientModel, opts ...cache.Option) BaseModel {
	return &customBaseModel{
		rds: rds,
		c:   conn,
	}
}

// Exec 原生执行语句
func (b *customBaseModel) Exec(sql string, args ...any) error {
	db, err := b.c.DB()
	if err != nil {
		return err
	}
	_, err = db.Exec(sql, args...)
	return err
}

func parseContext(ctx context.Context) *utils.LoggedInUser{
	if user := ctx.Value(utils.ContextType("user")); user != nil {
		return user.(*utils.LoggedInUser)
	}
	return &utils.LoggedInUser{SiteName: "null"}
}

// QueryCache 查询带缓存数据
func (b *customBaseModel) QueryCache(ctx context.Context, key, ql string, args ...any) (map[string]string, error) {
	var (
		err error
		ret = make(map[string]string, 1)
	)

	pctx := parseContext(ctx)
	ckey := fmt.Sprintf("model:site:%s:%s:%s", pctx.SiteName, key, utils.Md5(fmt.Sprintf("%s%v", ql, args)))
	if ok, _ := b.rds.GetCache(ckey, &ret); ok {
		return ret, nil
	}

	if ret, err = b.Query(ql, args...); err != nil {
		return nil, err
	}

	if pctx.DataCacheTTL > 0 {
		b.rds.SetCache(ckey, ret, time.Duration(pctx.DataCacheTTL)*time.Second)
	} else {
		b.rds.SetCache(ckey, ret, b.rds.TimeOut)
	}
	return ret, nil
}

// QueryListCache 原生查询语句带缓存
func (b *customBaseModel) QueryListCache(ctx context.Context, key, ql string, args ...any) ([]map[string]string, error) {
	var (
		err error
		rdsCli = b.rds
		ret = make([]map[string]string, 0)
	)

	pctx := parseContext(ctx)
	ckey := fmt.Sprintf("model:site:%s:%s:%s", pctx.SiteName, key, utils.Md5(fmt.Sprintf("%s%v", ql, args)))
	if ok, _ := rdsCli.GetCache(ckey, &ret); ok {
		return ret, nil
	}
	if ok, _ := rdsCli.GetCache(ckey, &ret); ok {
		return ret, nil
	}

	if ret, err = b.QueryList(ql, args...); err != nil {
		return nil, err
	}

	if pctx.DataCacheTTL > 0 {
		rdsCli.SetCache(ckey, ret, time.Duration(pctx.DataCacheTTL)*time.Second)
	} else {
		rdsCli.SetCache(ckey, ret, rdsCli.TimeOut)
	}

	return ret, nil
}

// Query 原生查询语句
func (b *customBaseModel) Query(ql string, args ...any) (map[string]string, error) {
	db, err := b.c.DB()
	if err != nil {
		return nil, err
	}

	rows, err := db.Query(ql, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	columns, _ := rows.Columns()
	cLen := len(columns)
	ret := make(map[string]string, cLen)
	for rows.Next() {
		values := make([]any, cLen)
		valuePtrs := make([]any, cLen)
		for i := range values {
			valuePtrs[i] = &values[i]
		}
		if err := rows.Scan(valuePtrs...); err != nil {
			return nil, err
		}
		for i := 0; i < cLen; i++ {
			ret[columns[i]] = typeToString(values[i])
		}
	}

	return ret, nil
}

// QueryList 原生查询语句
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

// QueryFieldList 原生查询语句
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

	if !strings.Contains(where, "deleteTs") {
		where = "where deleteTs=0 " + and + where
		where = strings.TrimSuffix(where, "AND ")
	} else if where != "" {
		where = "where " + where
	}
	if limit != "" && !strings.Contains(sw, " limit ") {
		where += " LIMIT " + limit
	}
	return where
}

func typeToString(v any) string {
	value := reflect.ValueOf(v)
	if !value.IsValid() {
		return ""
	}

	vt := value.Type().String()
	switch vt {
	case "string":
		return value.String()
	case "int64", "int32", "int16", "int8", "int":
		return strconv.FormatInt(value.Int(), 10)
	case "uint64", "uint", "uint32", "uint16", "uint8", "byte":
		return strconv.FormatUint(value.Uint(), 10)
	case "float64", "float32":
		return strconv.FormatFloat(value.Float(), 'f', -1, 64)
	case "[]uint8":
		return string(value.Bytes())
	case "bool":
		if vb := value.Bool(); vb {
			return "true"
		}
		return "false"
	}
	return ""
}

// Name2Case 驼峰转下划线
func Name2Case(str string) string {
	m := make([]rune, 0, 10)
	for k, v := range str {
		if k == 0 && IsWordEn(v) {
			v += 32
		} else if IsWordEn(v) {
			m = append(m, '_')
			v += 32
		}
		m = append(m, v)
	}
	return string(m)
}

func IsWordEn(s rune) bool {
	return s >= 65 && s <= 90
}

func Md5(data string) string {
	return fmt.Sprintf("%x", md5.Sum([]byte(data)))
}

// GetOffsetLimit 根据给出的参数获取分页数据
func GetOffsetLimit(page, size int32) string {
	if page <= 0 {
		page = 1
	}
	if size <= 0 {
		size = 10
	}
	return fmt.Sprintf(" LIMIT %d,%d", page*size-size, size)
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