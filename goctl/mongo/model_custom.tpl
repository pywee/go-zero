package model

{{if .Cache}}import (
    "context"

    "github.com/jinzhu/copier"
    "gitea.bluettipower.com/bluettipower/zerocommon/converters"
    "gitea.bluettipower.com/bluettipower/zerocommon/where"
    "github.com/zeromicro/go-zero/core/stores/cache"
    "github.com/zeromicro/go-zero/core/stores/monc"
    "go.mongodb.org/mongo-driver/bson"
){{else}}import (
    "context"

    "github.com/jinzhu/copier"
    "go.mongodb.org/mongo-driver/bson"
    "gitea.bluettipower.com/bluettipower/zerocommon/converters"
    "gitea.bluettipower.com/bluettipower/zerocommon/where"
    "github.com/zeromicro/go-zero/core/stores/mon"
{{end}}

{{if .Easy}}
const {{.Type}}CollectionName = "{{.snakeType}}"
{{end}}

var _ {{.Type}}Model = (*custom{{.Type}}Model)(nil)

type (
    // {{.Type}}Model is an interface to be customized, add more methods here,
    // and implement the added methods in custom{{.Type}}Model.
    {{.Type}}Model interface {
        {{.lowerType}}Model
	Get{{.Type}}ById (context.Context, string) (*{{.Type}}, error)
	Get{{.Type}}ByWhere (context.Context, string, ...interface{}) (*{{.Type}}, error)
	Get{{.Type}}ListByWhere (context.Context, string, ...interface{}) ([]*{{.Type}}, int64)
	Count{{.Type}}ByWhere(context.Context, string, ...interface{}) int64
	Delete{{.Type}}ByWhere(context.Context, string, ...interface{}) error
	Update{{.Type}}(context.Context, *{{.Type}}) error
    }

    custom{{.Type}}Model struct {
        *default{{.Type}}Model
    }
)

// New{{.Type}}Model returns a model for the mongo.
{{if .Easy}}func New{{.Type}}Model(url, db string{{if .Cache}}, c cache.CacheConf{{end}}) {{.Type}}Model {
    conn := {{if .Cache}}monc{{else}}mon{{end}}.MustNewModel(url, db, {{.Type}}CollectionName{{if .Cache}}, c{{end}})
    return &custom{{.Type}}Model{
        default{{.Type}}Model: newDefault{{.Type}}Model(conn),
    }
}{{else}}func New{{.Type}}Model(url, db, collection string{{if .Cache}}, c cache.CacheConf{{end}}) {{.Type}}Model {
    conn := {{if .Cache}}monc{{else}}mon{{end}}.MustNewModel(url, db, collection{{if .Cache}}, c{{end}})
    return &custom{{.Type}}Model{
        default{{.Type}}Model: newDefault{{.Type}}Model(conn),
    }
}{{end}}

// Get{{.Type}}ByWhere 根据条件获取单条记录
func (m *custom{{.Type}}Model) Get{{.Type}}ByWhere(ctx context.Context, conditions string, params ...interface{}) (*{{.Type}}, error) {
	var ret *{{.Type}}
	list, _ := m.Get{{.Type}}ListByWhere(ctx, conditions, params...)
	if len(list) > 0 {
		return list[0], nil
	}
	return ret, nil
}

// Get{{.Type}}ListByWhere 获取列表
func (m *custom{{.Type}}Model) Get{{.Type}}ListByWhere(ctx context.Context, conditions string, params ...interface{}) ([]*{{.Type}}, int64) {
	var list []*{{.Type}}
	opt := where.Parse(conditions, params...)
	if err := m.conn.Find(ctx, &list, opt.Filter, opt.Options); err != nil {
		return nil, 0
	}

	total, _ := m.conn.CountDocuments(ctx, opt.Filter)
	return list, total
}

// Get{{.Type}}ById 根据 ID 获取 {{.Type}} 单条数据
func (m *custom{{.Type}}Model) Get{{.Type}}ById(ctx context.Context, ID string) (*{{.Type}}, error) {
	return m.FindOne(ctx, ID)
}

// Count{{.Type}}ByWhere 根据 where 条件统计 {{.Type}} 数量
func (m *custom{{.Type}}Model) Count{{.Type}}ByWhere(ctx context.Context, conditions string, params ...interface{}) int64 {
	opt := where.Parse(conditions, params...)
	count, _ := m.conn.CountDocuments(ctx, opt.Filter)
	return count
}

// Delete{{.Type}}ByWhere 批量删除
func (m *custom{{.Type}}Model) Delete{{.Type}}ByWhere(ctx context.Context, conditions string, params ...interface{}) error {
	opt := where.Parse(conditions, params...)
	_, err := m.conn.UpdateManyNoCache(ctx, opt.Filter, bson.M{"$set": bson.M{"deleted": 1}})
	return err
}

// Update{{.Type}} 更新单条 {{.Type}} 记录
func (m *custom{{.Type}}Model) Update{{.Type}}(ctx context.Context, data *{{.Type}}) error {
	ret, err := m.Get{{.Type}}ById(ctx, data.ID.Hex())
	if err != nil {
		return err
	}

	err = copier.CopyWithOption(ret, data, copier.Option{IgnoreEmpty: true, DeepCopy: true, Converters: []copier.TypeConverter{converters.ObjectIdToStringConverter(), converters.TimeToInt64()}})
	if err != nil {
		return err
	}
	if _, err = m.Update(ctx, ret); err != nil {
		return err
	}
	return nil
}

// Update{{.Type}}ByWhere 根据条件更新多个 {{.Type}}
// func (m *custom{{.Type}}Model) Update{{.Type}}ByWhere(ctx context.Context, data map[string]interface{}, conditions string, params ...interface{} ) error {
	// opt := where.Parse(conditions, params...)
	// if _, err := m.conn.UpdateMany(ctx, bson.M{"$set": data}, opt.Filter, params...); err != nil {
		// return err
	// }
	// return nil
// }
