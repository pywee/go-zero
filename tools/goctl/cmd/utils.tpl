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

type LoggedInUser struct {
	Token        string `json:"token"`                  // Token 用户登录态
	Id           int64  `json:"id"`                     // 主键
	Wid          int64  `json:"wid"`                    // 登录中的站点 ID
	Domain       string `json:"domain"`                 // 登录中的站点域名
	Index        string `json:"index"`                  // 登录中的站点首页 (不包含 sign 标识)
	SiteName     string `json:"siteName"`               // 登录中的站点名称
	TplName      string `json:"tplName"`                // TplName 网站模板名称
	Name         string `json:"name"`                   // 用户名
	Type         int8   `json:"type,omitempty"`         // 类型 [1.管理员(全局超级管理员); 10.超级管理员(B端); 20.前台普通用户]
	Gender       int8   `json:"gender,omitempty"`       // 性别 [0.未知; 1.男; 2.女]
	Birthday     int32  `json:"birthday,omitempty"`     // 生日
	Email        string `json:"email"`                  // email
	Phone        string `json:"phone,omitempty"`        // 手机号
	Role         int8   `json:"role,omitempty"`         // 角色 [1.超级管理员; 10.普通管理员; 20.普通用户]
	Avatar       string `json:"avatar,omitempty"`       // 缩略图
	MaxWebs      int8   `json:"maxWebs,omitempty"`      // 用户最多可拥有的站点数量
	ClientIP     string `json:"clientIP,omitempty"`     // 客户端 IP 地址
	DataCacheTTL int64  `json:"dataCacheTTL,omitempty"` // 数据缓存时间（秒）
	HtmlCacheTTL int64  `json:"htmlCacheTTL,omitempty"` // 页面(静态)缓存时间（秒）
	CreateTs     int64  `json:"createTs"`               // 创建时间
	UpdateTs     int64  `json:"updateTs"`               // 修改时间
}

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

// GetOffsetLimit 根据给出的参数获取分页数据
func GetOffsetLimit(page, size int32) string {
	if page <= 0 {
		page = 1
	}
	if size <= 0 {
		size = 10
	}
	return fmt.Sprintf(" LIMIT %d,%d", page*size-size, size)
}

// VerifyEmail 验证邮箱格式是否正确
func VerifyEmail(email string) bool {
	regex := `^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$`
	re := regexp.MustCompile(regex)
	return re.MatchString(email)
}

func MaskEmail(email string) string {
	parts := strings.Split(email, "@")
	if len(parts) != 2 {
		return email // 非法邮箱格式，直接返回原文
	}

	local := parts[0]
	domain := parts[1]

	// 保留前1后1，其余用 * 替代
	if len(local) <= 2 {
		return local[:1] + "*" + "@" + domain
	}

	masked := local[:1] + strings.Repeat("*", len(local)-2) + local[len(local)-1:]
	return masked + "@" + domain
}

func MaskUsername(name string) string {
	n := len(name)
	switch {
	case n == 0:
		return ""
	case n == 1:
		return "*"
	case n == 2:
		return name[:1] + "*"
	default:
		return name[:1] + strings.Repeat("*", n-2) + name[n-1:]
	}
}

