package utils

import (
	"math/rand"
	"strconv"
	"time"
)

// randSource 生成一个 0.0 到 1.0 的随机数
var randSource = rand.New(rand.NewSource(time.Now().UnixNano()))

const letterBytes = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-"

// Rand 生成指定个数的随机数
func Rand(num int) string {
	r := ""
	for i := 0; i < num; i++ {
		number := randSource.Intn(10)
		r += strconv.Itoa(number)
	}
	return r
}

func RandNum(min, max int) int {
	return randSource.Intn(max-min+1) + min
}

// RandString 生成随机字符串
// 第一个和最后一个字符不能是 _ 或 -
func RandString(length int) string {
	result := make([]byte, length)
	letterBytesLen := len(letterBytes)
	for i := range result {
		var r byte
		if i == 0 || i == length-1 {
			for {
				if r = letterBytes[randSource.Intn(letterBytesLen)]; r != '_' && r != '-' {
					break
				}
			}
		} else {
			r = letterBytes[randSource.Intn(letterBytesLen)]
		}
		result[i] = r
	}
	return string(result)
}

type Prize struct {
	ID     int32
	Chance float64
}

// Lottery 抽奖函数，接收奖品列表并返回中奖奖品名称
func Lottery(prizes []*Prize) *Prize {

	// 计算总的中奖几率
	// 并根据该几率计算出随机数最大取值范围
	totalChance := 0.0
	for _, p := range prizes {
		totalChance += p.Chance
	}

	// randNum := r.Float64() * totalChance
	randNum := randSource.Float64() * 1

	cumulativeChance := 0.0
	for _, p := range prizes {
		cumulativeChance += p.Chance
		if randNum < cumulativeChance {
			return p
		}
	}
	return nil
}