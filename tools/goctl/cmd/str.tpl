package utils

import (
	"errors"
	"fmt"
	"regexp"
	"strconv"
	"strings"
)

// RemoveHTMLStyle 去掉HTML样式代码
func RemoveHTMLStyle(src string) string {
	// re, _ := regexp.Compile(`\<[\S\s]+?\>`)
	// src = re.ReplaceAllStringFunc(src, strings.ToLower)

	// 去除STYLE
	re, _ := regexp.Compile(`\<style[\S\s]+?\</style\>`)
	src = re.ReplaceAllString(src, "")

	// 去除SCRIPT
	re, _ = regexp.Compile(`\<script[\S\s]+?\</script\>`)
	src = re.ReplaceAllString(src, "")

	// 去除所有尖括号内的HTML代码
	re, _ = regexp.Compile(`\<[\S\s]+?\>`)
	src = re.ReplaceAllString(src, "")

	// 去除换行符等
	src = strings.Replace(src, "\n", "", -1)
	src = strings.Replace(src, "\t", "", -1)
	// src = strings.Replace(src, " ", "", -1)

	// 去除连续的换行符
	// re, _ = regexp.Compile(`\\s{2,}`)
	re, _ = regexp.Compile(` {2,}`)
	src = re.ReplaceAllString(src, "")

	res := strings.NewReplacer(
		"&lt;", "",
		"&gt;", "",
	)
	src = res.Replace(src)

	return strings.TrimSpace(src)
}

// ToString 任何类型转换为字符串
func ToString(src any) (string, error) {
	if t := fmt.Sprintf("%T", src); t == "string" {
		return src.(string), nil
	} else if t == "int" || t == "int8" || t == "int16" || t == "int32" || t == "int64" || t == "uint" || t == "uint8" || t == "uint16" || t == "uint32" || t == "uint64" {
		return fmt.Sprintf("%d", src), nil
	} else if t == "bool" {
		if src.(bool) {
			return "true", nil
		}
		return "false", nil
	} else if t == "float32" || t == "float64" {
		return strconv.FormatFloat(src.(float64), 'f', -1, 64), nil
	}
	return "", errors.New("unsupported type")
}