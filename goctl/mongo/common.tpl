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