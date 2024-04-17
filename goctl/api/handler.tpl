package {{.PkgName}}

import (
	"net/http"

	"github.com/pywee/mw/utils"
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
		l := {{.LogicName}}.New{{.LogicType}}(r.Context(), svcCtx)
		{{if .HasResp}}resp, {{end}}err := l.{{.Call}}({{if .HasRequest}}&req{{end}})
		utils.JSON(w, resp, err)
		{{if .HasResp}}// response.Response(w, resp, err){{else}}// response.Response(w, nil, err){{end}}
	}
}