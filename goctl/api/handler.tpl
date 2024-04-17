package {{.PkgName}}

import (
	"net/http"
	"strings"
	"reflect"

	"github.com/zeromicro/go-zero/rest/httpx"
	"gitea.bluettipower.com/bluettipower/zerocommon/response"
	
	{{.ImportPackages}}
)

// ......
func {{.HandlerName}}(svcCtx *svc.ServiceContext) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		{{if .HasRequest}}var req types.{{.RequestType}}
		if err := httpx.Parse(r, &req); err != nil {
			httpx.ErrorCtx(r.Context(), w, err)
			return
		}{{end}}

		trimStringFields(&req)
		l := {{.LogicName}}.New{{.LogicType}}(r.Context(), svcCtx)
		{{if .HasResp}}resp, {{end}}err := l.{{.Call}}({{if .HasRequest}}&req{{end}})
		{{if .HasResp}}response.Response(w, resp, err){{else}}response.Response(w, nil, err){{end}}
	}
}

func trimStringFields(s interface{}) {
	value := reflect.ValueOf(s)
	if value.Kind() == reflect.Ptr {
		value = value.Elem()
	}

	if value.Kind() != reflect.Struct {
		return
	}

	for i := 0; i < value.NumField(); i++ {
		field := value.Field(i)
		if field.Type().Kind() == reflect.String && value.Field(i).CanSet() {
			value.Field(i).SetString(strings.TrimSpace(field.String()))
		}
	}
}


