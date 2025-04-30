package {{.pkgName}}

import (
	{{.imports}}
	"github.com/pywee/fangzhoucms/utils"
)

type {{.logic}} struct {
	logx.Logger
	osType uint8
	ctx    context.Context
	user   *utils.LoggedInUser
	svcCtx *svc.ServiceContext
}

func New{{.logic}}(ctx context.Context, svcCtx *svc.ServiceContext) *{{.logic}} {
	var u *utils.LoggedInUser
	if user := ctx.Value(utils.ContextType("user")); user != nil {
		u = user.(*utils.LoggedInUser)
	}
	return &{{.logic}}{
		ctx:    ctx,
		user:   u,
		svcCtx: svcCtx,
		osType: svcCtx.GetOsType(ctx),
	}
}

// {{if eq .function "Create"}}Create 新增 {{.serviceName}}{{else if eq "List" .function}}List 获取 {{.serviceName}} 列表数据{{else if eq .function "Del"}}Del 删除 {{.serviceName}} 数据{{else if eq .function "Update"}}List 更新 {{.serviceName}} 数据{{else if eq .function "Get"}}获取 {{.serviceName}} 单条记录{{else}}{{.function}}{{end}}
func (l *{{.logic}}) {{.function}}({{.request}}) {{.responseType}} {
	return &types.{{.responseTypeName}}{}, nil
}
