package {{.PkgName}}

import (
	"context"
	"net/http"
	"strings"
	{{.ImportPackages}}
	// "github.com/pywee/{{.ServiceName}}/common"
	"github.com/pywee/{{.ServiceName}}/utils"
	"github.com/zeromicro/go-zero/rest/httpx"
)

func {{.HandlerName}}(svcCtx *svc.ServiceContext) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		{{if .HasRequest}}var req types.{{.RequestType}}
		if err := httpx.Parse(r, &req); err != nil {
			// httpx.ErrorCtx(r.Context(), w, err)
			utils.JSON(w, r, err)
			return
		}{{end}}

		if err := utils.TrimStringFields(&req); err != nil {
			utils.JSON(w, r, err)
			return
		}

		ctx := context.WithValue(r.Context(), utils.CtxDomain, strings.ToLower(r.Host))
		l := {{.LogicName}}.New{{.LogicType}}(ctx, svcCtx)
		{{if .HasResp}}resp, {{end}}err := l.{{.Call}}({{if .HasRequest}}&req{{end}})
		utils.JSON(w, resp, err){{if .HasResp}}{{end}}	
	}
}