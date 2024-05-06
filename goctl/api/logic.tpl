package {{.pkgName}}

import (
	{{.imports}}{{if eq .function "Update"}}
	"github.com/jinzhu/copier"{{else if eq .function "Get"}}
	"github.com/jinzhu/copier"{{else if eq .function "Create"}}
	"errors"
	"github.com/jinzhu/copier"{{else if eq .function "List"}}
	"github.com/jinzhu/copier"
	{{end}}
)

type {{.logic}} struct {
	logx.Logger
	Uid int64
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func New{{.logic}}(ctx context.Context, svcCtx *svc.ServiceContext) *{{.logic}} {
	return &{{.logic}}{
		ctx:    ctx,
		svcCtx: svcCtx,
		Uid: svcCtx.UID(ctx),
		Logger: logx.WithContext(ctx),
	}
}

// {{if eq .function "Create"}}Create 新增 {{.serviceName}}{{else if eq "List" .function}}List 获取 {{.serviceName}} 列表数据{{else if eq .function "Del"}}Del 删除 {{.serviceName}} 数据{{else if eq .function "Update"}}List 更新 {{.serviceName}} 数据{{else if eq .function "Get"}}获取 {{.serviceName}} 单条记录{{else}}{{.function}}{{end}}
func (l *{{.logic}}) {{.function}}({{.request}}) {{.responseType}} {
	{{if eq .function "Del"}}if err := l.svcCtx.{{.serviceName}}Model.Delete(l.ctx, req.ID); err != nil {
		return nil, err
	}
	return &types.{{.responseTypeName}}{}, nil{{else if eq .function "Update"}}ret, err := l.svcCtx.{{.serviceName}}Model.Get{{.serviceName}}ById(l.ctx, req.ID)
	if err != nil {
		return nil, err
	}

	if err = copier.CopyWithOption(ret, req, copier.Option{IgnoreEmpty: true, DeepCopy: true}); err != nil {
		return nil, err
	}

	if _, err := l.svcCtx.{{.serviceName}}Model.Update(l.ctx, ret); err != nil {
		return nil, err
	}
	return &types.Update{{.serviceName}}Resp{}, nil{{else if eq .function "Get"}}ret, err := l.svcCtx.{{.serviceName}}Model.Get{{.serviceName}}ById(l.ctx, req.ID)
	if err != nil {
		return nil, err
	}
	var data types.Get{{.serviceName}}Resp
	if err := copier.CopyWithOption(&data, ret, copier.Option{IgnoreEmpty: true, DeepCopy: true}); err != nil {
		return nil, err
	}
	return &data, nil{{else if eq .function "Create"}}sql := `conditions`
	if count := l.svcCtx.{{.serviceName}}Model.Count{{.serviceName}}ByWhere(l.ctx, sql); count > 0 {
		return nil, errors.New("")
	}

	var data model.{{.serviceName}}
	if err := copier.CopyWithOption(&data, req, copier.Option{IgnoreEmpty: true, DeepCopy: true}); err != nil {
		return nil, err
	}

	id, err := l.svcCtx.{{.serviceName}}Model.Insert(l.ctx, &data)
	if err != nil {
		return nil, err
	}
	return &types.Create{{.serviceName}}Resp{ID: id}, nil{{else if eq .function "List"}}var (
		ret []*types.{{.serviceName}}Column
		sql string
	)
	
	// sql += model.ParseLimit(req.Current, req.Size)
	list, total := l.svcCtx.{{.serviceName}}Model.Get{{.serviceName}}ListByWhere(l.ctx, sql)
	err := copier.CopyWithOption(&ret, &list, copier.Option{IgnoreEmpty: true, DeepCopy: true})
	if err != nil {
		return nil, err
	}

	return &types.Get{{.serviceName}}ListResp {Total: total, List:  ret}, nil{{else}}return &types.{{.responseTypeName}}{}, nil{{end}}
}
