package utils

import (
	"crypto/md5"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"fmt"
	"math/rand"
	"reflect"
	"regexp"
	"strconv"
	"strings"
	"time"
)

type ContextType string

// UserModel 此处用于保存用户登录态
type UserModel struct {
	ID       int64  `json:"id"`
	Name     string `json:"name"`
	Avator   string `json:"avator"`
	Phone    string `json:"phone"`
	UpdateTs int64  `json:"updateTs"`
	CreateTs int64  `json:"createTs"`
}

// randSource 生成随机数
var randSource = rand.New(rand.NewSource(time.Now().UnixNano()))

var phoneVers = []string{
	"188",
	"134",
	"135",
	"137",
	"138",
	"136",
	"189",
	"131",
	"132",
	"133",
	"139",
	"145",
	"150",
	"151",
	"152",
	"153",
	"154",
	"155",
	"156",
	"157",
	"158",
	"159",
	"181",
	"182",
	"183",
	"186",
	"199",
	"176",
}

// TrimStringFields 入参检查
func TrimStringFields(s interface{}) error {
	value := reflect.ValueOf(s)
	if value.Kind() == reflect.Ptr {
		value = value.Elem()
	}
	if value.Kind() != reflect.Struct {
		return nil
	}

	typ := value.Type()
	for i := 0; i < value.NumField(); i++ {
		field := value.Field(i)
		typeField := typ.Field(i)
		tag := typeField.Tag
		fieldName := typeField.Name

		if j := tag.Get("json"); j != "" {
			fieldName = j
		} else if j = tag.Get("path"); j != "" {
			fieldName = j
		} else if j = tag.Get("header"); j != "" {
			fieldName = j
		}

		required := strings.Contains(fieldName, ",required")
		if idx := strings.Index(fieldName, ","); idx != -1 {
			fieldName = strings.TrimSpace(fieldName[:idx])
		}

		if ft := field.Type().Kind(); ft == reflect.String {
			trimedField := strings.TrimSpace(field.String())
			if required && trimedField == "" {
				return errors.New("the value of field '" + fieldName + "' can not be empty")
			}
			if field.CanSet() {
				value.Field(i).SetString(trimedField)
			}
		} else if required && ft >= 2 && ft <= 6 && field.Int() == 0 {
			return errors.New("field '" + fieldName + "' can not be zero")
		} else if ft >= 7 && ft <= 11 && required && field.Uint() == 0 {
			return errors.New("field '" + fieldName + "' can not be zero")
		} else if required && (ft == 13 || ft == 14) && field.Float() == 0 {
			return errors.New("field '" + fieldName + "' can not be zero")
		} else if ft == reflect.Struct {
			s := value.FieldByName(fieldName)
			for j := 0; j < s.NumField(); j++ {
				if sf := s.Field(j); sf.Type().Kind() == reflect.String && sf.CanSet() {
					sf.SetString(strings.TrimSpace(sf.String()))
				}
			}
		}
	}
	return nil
}

// Rand 生成指定个数的随机数
func Rand(num int) string {
	r := ""
	for i := 0; i < num; i++ {
		number := randSource.Intn(10)
		r += strconv.Itoa(number)
	}
	return r
}

type Prize struct {
	ID     int32
	Chance float64
}

// Lottery 抽奖函数，接收奖品列表并返回中奖奖品名称
func Lottery(prizes []*Prize) *Prize {
	// 生成一个 0.0 到 1.0 的随机数
	r := rand.New(rand.NewSource(time.Now().UnixNano()))

	// 计算总的中奖几率
	// 并根据该几率计算出随机数最大取值范围
	totalChance := 0.0
	for _, p := range prizes {
		totalChance += p.Chance
	}

	// randNum := r.Float64() * totalChance
	randNum := r.Float64() * 1

	cumulativeChance := 0.0
	for _, p := range prizes {
		cumulativeChance += p.Chance
		if randNum < cumulativeChance {
			return p
		}
	}
	return nil
}

func SHA256(input string) string {
	hash := sha256.New()
	hash.Write([]byte(input))
	hashInBytes := hash.Sum(nil)
	return hex.EncodeToString(hashInBytes)
}

func Md5(data string) string {
	return fmt.Sprintf("%x", md5.Sum([]byte(data)))
}

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

// CheckUserName 校验用户名是否合法
// 允许中文+英文+数字+下划线的组合
func CheckUserName(name string) bool {
	if ok, _ := regexp.MatchString("^[0-9a-zA-Z_\u4e00-\u9fa5]+$", name); ok {
		return true
	}
	return false
}

// PhoneVerify 校验手机号是否合法
func PhoneVerify(phone string) bool {
	if ok, _ := regexp.MatchString(`^1[0-9]{10}$`, phone); !ok {
		return false
	}

	phoneOK := false
	phoneFix := phone[:3]
	for _, v := range phoneVers {
		if v == phoneFix {
			phoneOK = true
			break
		}
	}
	return phoneOK
}

// HPhone 隐藏手机号中间四位
func HPhone(phone string) string {
	if len(phone) != 11 {
		return phone
	}
	return phone[:3] + "****" + phone[7:]
}

func EncodeBase64(s string) string {
	return base64.StdEncoding.EncodeToString([]byte(s))
}

func DecodeBase64(s string) string {
	decoded, err := base64.StdEncoding.DecodeString(s)
	if err != nil {
		return ""
	}
	return string(decoded)
}