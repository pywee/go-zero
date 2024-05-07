package {{.pkg}}

import (
	"errors"

	"github.com/zeromicro/go-zero/core/stores/sqlx"
)

var (
	ErrNotFound    = sqlx.ErrNotFound
	NotFoundRecord = errors.New("找不到数据")
)

func IsErr(err error) bool {
	return err != nil && err != sqlx.ErrNotFound
}

func IsNotFound(err error) bool {
	return err == sqlx.ErrNotFound
}