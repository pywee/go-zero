package {{.PkgName}}

import (
	"net/http"
	"context"
	"strings"
	"github.com/pywee/{{.ServiceName}}/utils"
	"github.com/zeromicro/go-zero/rest/httpx"
	// "gitea.bluettipower.com/bluettipower/zerocommon/response"
	{{.ImportPackages}}
)

func {{.HandlerName}}(svcCtx *svc.ServiceContext) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		{{if .HasRequest}}var req types.{{.RequestType}}
		if err := httpx.Parse(r, &req); err != nil {
			httpx.ErrorCtx(r.Context(), w, err)
			return
		}{{end}}

		utils.TrimStringFields(&req)
		if token := r.Header.Get("f"); token != "" {
			r = r.WithContext(context.WithValue(r.Context(), utils.ContextType("token"), token))
		}

		var os string
		userAgent := r.Header.Get("User-Agent")
		if idx := strings.Index(userAgent, ")"); idx != -1 {
			userAgent = strings.ToLower(userAgent[:idx])
			if strings.Contains(userAgent, "android") {
				os = types.OsTypeAndroid
			} else if strings.Contains(userAgent, "ios") {
				os = types.OsTypeIOS
			} else if strings.Contains(userAgent, "pad") {
				os = types.OsTypePad
			}
		}

		l := {{.LogicName}}.New{{.LogicType}}(r.Context(), svcCtx, os)
		{{if .HasResp}}resp, {{end}}err := l.{{.Call}}({{if .HasRequest}}&req{{end}})
		utils.JSON(w, resp, err)
		{{if .HasResp}}// response.Response(w, resp, err){{else}}// response.Response(w, nil, err){{end}}
	}
}