package {{.pkg}}

import "github.com/zeromicro/go-zero/core/stores/sqlx"

var ErrNotFound = sqlx.ErrNotFound

func IsErr(err error) bool {
    return err != nil && err != sqlx.ErrNotFound
}

func IsNotFound(err error) bool {
    return err == sqlx.ErrNotFound
}