package utils

import (
	"crypto/md5"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"fmt"
	"reflect"
	"regexp"
	"strings"
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

		fieldName = strings.ReplaceAll(fieldName, " ", "")
		required := strings.Contains(fieldName, ",required")
		lower := strings.Contains(fieldName, ",lower")
		upper := strings.Contains(fieldName, ",upper")
		if idx := strings.Index(fieldName, ","); idx != -1 {
			fieldName = strings.TrimSpace(fieldName[:idx])
		}

		if ft := field.Type().Kind(); ft == reflect.String {
			trimedField := strings.TrimSpace(field.String())
			if required && trimedField == "" {
				return errors.New("the value of field '" + fieldName + "' can not be empty")
			}
			if field.CanSet() {
				if lower {
					trimedField = strings.ToLower(trimedField)
				} else if upper {
					trimedField = strings.ToUpper(trimedField)
				}
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

func SHA256(input string) string {
	hash := sha256.New()
	hash.Write([]byte(input))
	hashInBytes := hash.Sum(nil)
	return hex.EncodeToString(hashInBytes)
}

func Md5(data string) string {
	return fmt.Sprintf("%x", md5.Sum([]byte(data)))
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

func InArray(arr []string, str string) bool {
	for _, v := range arr {
		if v == str {
			return true
		}
	}
	return false
}
