package utils

import (
	"encoding/json"
	"net/http"
	"strings"
)

type Resp struct {
	Code int32  `json:"code"`
	Msg  string `json:"msg"`
	Data any    `json:"data,omitempty"`
}

func JSON(w http.ResponseWriter, ret any, err error) {
	w.WriteHeader(200)
	w.Header().Set("Content-Type", "application/json; charset=utf-8")

	var bs []byte
	if err != nil {
		if errStr := err.Error(); !strings.Contains(errStr, `code":`) {
			bs, _ = json.Marshal(Resp{Code: -1, Msg: errStr})
		} else {
			bs, _ = json.Marshal(err)
		}
	} else {
		bs, _ = json.Marshal(Resp{Data: ret})
	}
	w.Write(bs)
}

