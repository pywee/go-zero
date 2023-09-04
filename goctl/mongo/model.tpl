// Code generated by goctl. DO NOT EDIT.
package model

import (
    "context"
    "time"

    {{if .Cache}}"github.com/zeromicro/go-zero/core/stores/monc"{{else}}"github.com/zeromicro/go-zero/core/stores/mon"{{end}}
    "go.mongodb.org/mongo-driver/bson"
    "go.mongodb.org/mongo-driver/bson/primitive"
    "go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

{{if .Cache}}var prefix{{.Type}}CacheKey = "cache:{{.lowerType}}:"{{end}}

type {{.lowerType}}Model interface{
    Insert(ctx context.Context, data *{{.Type}}) (string, error)
    FindOne(ctx context.Context, id string) (*{{.Type}}, error)
	Find(ctx context.Context, filter interface{}, opt ...*options.FindOptions) ([]*{{.Type}}, error)
	Count(ctx context.Context, filter interface{}) int64
    Update(ctx context.Context, data *{{.Type}}) (*mongo.UpdateResult, error)
    Delete(ctx context.Context, id string) error
    DeleteMany(ctx context.Context, ids []string) error
}

type default{{.Type}}Model struct {
    conn {{if .Cache}}*monc.Model{{else}}*mon.Model{{end}}
}

func newDefault{{.Type}}Model(conn {{if .Cache}}*monc.Model{{else}}*mon.Model{{end}}) *default{{.Type}}Model {
    return &default{{.Type}}Model{conn: conn}
}

func (m *default{{.Type}}Model) Insert(ctx context.Context, data *{{.Type}}) (string, error) {
    if data.ID.IsZero() {
        data.ID = primitive.NewObjectID()
        if data.CreateAt.IsZero() {
            data.CreateAt = time.Now()
        }
        if data.UpdateAt.IsZero() {
            data.UpdateAt = time.Now()
        }
    }

    {{if .Cache}}key := prefix{{.Type}}CacheKey + data.ID.Hex(){{end}}
    ret, err := m.conn.InsertOne(ctx, {{if .Cache}}key, {{end}} data)
    if err != nil {
        return "", err
    }
    return ret.InsertedID.(primitive.ObjectID).Hex(), nil
}

// Find 原生批量获取数据
func (m *default{{.Type}}Model) Find(ctx context.Context, filter interface{}, opt ...*options.FindOptions) ([]*{{.Type}}, error) {
	var data []*{{.Type}}
	err := m.conn.Find(ctx, &data, filter, opt...)
	if err != nil {
		return nil, err
	}
	return data, nil
}

// Count 原生统计某条件下的行数
func (m *default{{.Type}}Model) Count(ctx context.Context, filter interface{}) int64 {
	count, _ := m.conn.CountDocuments(ctx, filter)
	return count
}

func (m *default{{.Type}}Model) FindOne(ctx context.Context, id string) (*{{.Type}}, error) {
    oid, err := primitive.ObjectIDFromHex(id)
    if err != nil {
        return nil, ErrInvalidObjectId
    }

    var data {{.Type}}
    {{if .Cache}}key := prefix{{.Type}}CacheKey + id{{end}}
    err = m.conn.FindOne(ctx, {{if .Cache}}key, {{end}}&data, bson.M{"_id": oid,"deleted": bson.M{"$ne":1} })
    switch err {
    case nil:
        return &data, nil
    case {{if .Cache}}monc{{else}}mon{{end}}.ErrNotFound:
        return nil, ErrNotFound
    default:
        return nil, err
    }
}

func (m *default{{.Type}}Model) Update(ctx context.Context, data *{{.Type}}) (*mongo.UpdateResult, error) {
    data.UpdateAt = time.Now()
    {{if .Cache}}key := prefix{{.Type}}CacheKey + data.ID.Hex(){{end}}
    res, err := m.conn.UpdateOne(ctx, {{if .Cache}}key, {{end}}bson.M{"_id": data.ID}, bson.M{"$set": data})
    return res, err
}

func (m *default{{.Type}}Model) Delete(ctx context.Context, id string) error {
    oid, err := primitive.ObjectIDFromHex(id)
    if err != nil {
        return ErrInvalidObjectId
    }
	{{if .Cache}}key := prefix{{.Type}}CacheKey +id{{end}}
	_, err = m.conn.UpdateOne(ctx, {{if .Cache}}key, {{end}}bson.M{"_id": oid}, bson.M{"$set": bson.M{"deleted": 1} })
    {{if .Cache}}if err != nil {
		return err
	}
	err = m.conn.DelCache(ctx, key){{end}}
	return err
}

func (m *default{{.Type}}Model) DeleteMany(ctx context.Context, ids []string) error {
    var objectIDs []primitive.ObjectID
	{{if .Cache}} var keys []string {{end}}
	for _, id := range ids {
        oid, err := primitive.ObjectIDFromHex(id)
        if err != nil {
                return ErrInvalidObjectId
        }
        objectIDs = append(objectIDs, oid)
        {{if .Cache}}keys = append(keys, prefix{{.Type}}CacheKey+id){{end}}
	}
	_, err := m.conn.UpdateMany(ctx, {{if .Cache}}keys, {{end}}bson.M{"_id": bson.M{"$in": objectIDs}}, bson.M{"$set": bson.M{"deleted": 1} })
	return err
}