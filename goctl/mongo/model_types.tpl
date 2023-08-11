package model

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type {{.Type}} struct {
	// ID 主键 
	ID primitive.ObjectID `bson:"_id,omitempty" json:"id,omitempty"`

	// Deleted 是否删除 [0.正常; 1删除]
	Deleted  uint8     `bson:"deleted,omitempty" json:"deleted,omitempty"` 
	// DeleteAt 删除时间
	DeleteAt time.Time `bson:"deleteAt,omitempty" json:"deleteAt,omitempty"`
	// UpdateAt 更新时间
	UpdateAt time.Time `bson:"updateAt,omitempty" json:"updateAt,omitempty"`
	// CreateAt 创建时间
	CreateAt time.Time `bson:"createAt,omitempty" json:"createAt,omitempty"`
}
