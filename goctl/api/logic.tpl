package {{.pkgName}}

import (
	{{.imports}}{{if eq .function "Update"}}
	"github.com/pywee/fangzhoucms/utils"
	"github.com/jinzhu/copier"{{else if eq .function "Create"}} "errors"
	"github.com/jinzhu/copier"{{else if eq .function "List"}}
	"github.com/jinzhu/copier"{{end}}
)

type {{.logic}} struct {
	logx.Logger
	uid int64
	wid int64
	osType uint8
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func New{{.logic}}(ctx context.Context, svcCtx *svc.ServiceContext) *{{.logic}} {
	return &{{.logic}}{
		ctx:    ctx,
		svcCtx: svcCtx,
		uid: svcCtx.Uid(ctx),
		wid: svcCtx.Wid(ctx),
		osType: svcCtx.GetOsType(ctx),
	}
}

// {{if eq .function "Create"}}Create 新增 {{.serviceName}}{{else if eq "List" .function}}List 获取 {{.serviceName}} 列表数据{{else if eq .function "Del"}}Del 删除 {{.serviceName}} 数据{{else if eq .function "Update"}}List 更新 {{.serviceName}} 数据{{else if eq .function "Get"}}获取 {{.serviceName}} 单条记录{{else}}{{.function}}{{end}}
func (l *{{.logic}}) {{.function}}({{.request}}) {{.responseType}} {
	return &types.{{.responseTypeName}}{}, nil
}
