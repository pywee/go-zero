package utils

import (
	"time"
	"strings
)

// GetTimeDate 传入时间戳获取相对时间
// 取得指定时间戳当天初始时间
func GetTimeDate(ts int64, addDay int) time.Time {
	var cstSh, _ = time.LoadLocation("Asia/Shanghai")
	b := time.Unix(ts, 0)
	b = b.In(cstSh)
	year, month, day := b.Date()
	return time.Date(year, month, day, 0, 0, 0, 0, time.Now().Location()).AddDate(0, 0, addDay)
}

// GetMonthTimeDate 传入时间戳获取相对时间
// 取得指定月份戳初始时间
func GetMonthTimeDate(ts int64, mon int) time.Time {
	var cstSh, _ = time.LoadLocation("Asia/Shanghai")
	b := time.Unix(ts, 0)
	b = b.In(cstSh)
	year, month, day := b.Date()
	return time.Date(year, month, day, 0, 0, 0, 0, time.Now().Location()).AddDate(0, mon, 0)
}

// GetThisMonthTime 获取某月第一天的时间
// 传入0获取本月，-1获取上月，1获取下月
func GetThisMonthTime(m time.Month) time.Time {
	year, month, _ := time.Now().Date()
	month += m
	return time.Date(year, month, 1, 0, 0, 0, 0, time.Local)
}

// GetZeroTs 获取当前日期的零点时间戳
// 加载 Asia/Shanghai 时区（更标准，支持夏令时等）
// 要求 dateStr 格式为 "2006-01-02"
func GetZeroTs(dateStr string) int64 {
	dateStr = strings.ReplaceAll(dateStr, "/", "-")
	layout := "2006-01-02"
	loc, err := time.LoadLocation("Asia/Shanghai")
	if err != nil {
		return 0
	}
	t, err := time.ParseInLocation(layout, dateStr, loc)
	if err != nil {
		return 0
	}
	return t.Unix()
}