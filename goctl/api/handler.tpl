package {{.PkgName}}

import (
	"net/http"
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

		l := {{.LogicName}}.New{{.LogicType}}(r.Context(), svcCtx)
		{{if .HasResp}}resp, {{end}}err := l.{{.Call}}({{if .HasRequest}}&req{{end}})
		utils.JSON(w, resp, err){{if .HasResp}}{{end}}	
	}
}