package model

import "fmt"

// ParseLimit 解析前端传入的 page/size 转换为 limit 句子
func ParseLimit(page, size int64) string {
	if page <= 0 {
		page = 1
	}
	if size <= 0 {
		size = 10
	}

	return fmt.Sprintf(" limit %d,%d", (page*size)-size, size)
}

// for k, v := range conditions {
// filter = append(filter, bson.E{Key: k, Value: v})
// }

//_ = bson.D{
//	bson.E{Key: "sku", Value: bson.M{"$ne": "kkk333"}},
//	bson.E{Key: "$or", Value: bson.A{
//		bson.D{bson.E{Key: "name", Value: "test1"}},
//		bson.D{bson.E{Key: "name", Value: "test3"}},
//	}},
//}

// buf, _ := json.MarshalIndent(filter, "", " ")
// fmt.Println(string(buf))