package {{.pkgName}}

import (
	{{.imports}}{{if eq .function "Update"}}
	"github.com/jinzhu/copier"
	"gitea.bluettipower.com/bluettipower/zerocommon/converters"{{else if eq .function "Get"}}
	"github.com/jinzhu/copier"
	"gitea.bluettipower.com/bluettipower/zerocommon/converters"{{else if eq .function "Create"}}
	"fmt"
	"errors"
	"github.com/jinzhu/copier"
	"gitea.bluettipower.com/bluettipower/delivery-service/model"
	"gitea.bluettipower.com/bluettipower/zerocommon/converters"{{else if eq .function "List"}}
	"fmt"
	"github.com/jinzhu/copier"
	"gitea.bluettipower.com/bluettipower/zerocommon/converters"
	{{end}}
)

type {{.logic}} struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func New{{.logic}}(ctx context.Context, svcCtx *svc.ServiceContext) *{{.logic}} {
	return &{{.logic}}{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

// {{if eq .function "Create"}}Create 新增 {{.serviceName}}{{else if eq "List" .function}}List 获取 {{.serviceName}} 列表数据{{else if eq .function "Del"}}Del 删除 {{.serviceName}} 数据{{else if eq .function "Update"}}List 更新 {{.serviceName}} 数据{{else if eq .function "Get"}}获取 {{.serviceName}} 单条记录{{end}}
func (l *{{.logic}}) {{.function}}({{.request}}) {{.responseType}}  {
	{{if eq .function "Del"}}if err := l.svcCtx.{{.serviceName}}Model.Delete(l.ctx, req.ID); err != nil {
		return nil, err
	}
	return &types.{{.responseTypeName}}{ID: req.ID}, nil{{else if eq .function "Update"}}ret, err := l.svcCtx.{{.serviceName}}Model.Get{{.serviceName}}ById(l.ctx, req.ID)
	if err != nil {
		return nil, err
	}

	if err = copier.CopyWithOption(ret, req, copier.Option{IgnoreEmpty: true, DeepCopy: true, Converters: []copier.TypeConverter{converters.ObjectIdToStringConverter(), converters.TimeToInt64()}}); err != nil {
		return nil, err
	}

	if _, err := l.svcCtx.{{.serviceName}}Model.Update(l.ctx, ret); err != nil {
		return nil, err
	}
	return &types.Update{{.serviceName}}Resp{ID: req.ID}, nil{{else if eq .function "Get"}}ret, err := l.svcCtx.{{.serviceName}}Model.Get{{.serviceName}}ById(l.ctx, req.ID)
	if err != nil {
		return nil, err
	}
	var data types.Get{{.serviceName}}Resp
	if err := copier.CopyWithOption(&data, ret, copier.Option{IgnoreEmpty: true, DeepCopy: true, Converters: []copier.TypeConverter{converters.ObjectIdToStringConverter(), converters.TimeToInt64()}}); err != nil {
		return nil, err
	}
	return &data, nil{{else if eq .function "Create"}}sql := fmt.Sprintf(`conditions`)
	if count := l.svcCtx.{{.serviceName}}Model.Count{{.serviceName}}ByWhere(l.ctx, sql); count > 0 {
		return nil, errors.New("      ")
	}

	var data model.{{.serviceName}}
	if err := copier.CopyWithOption(&data, req, copier.Option{IgnoreEmpty: true, DeepCopy: true, Converters: []copier.TypeConverter{converters.StringToObjectIdConverter(), converters.TimeToInt64()}}); err != nil {
		return nil, err
	}

	id, err := l.svcCtx.{{.serviceName}}Model.Insert(l.ctx, &data)
	if err != nil {
		return nil, err
	}
	return &types.Create{{.serviceName}}Resp{ID: id}, nil{{else if eq .function "List"}}sql := ""
	if req.Status > 0 {
		sql += fmt.Sprintf(`status=%d`, req.Status)
	}

	var ret []types.{{.serviceName}}Column
	list, total := l.svcCtx.{{.serviceName}}Model.Get{{.serviceName}}ListByWhere(l.ctx, sql)
	err := copier.CopyWithOption(&ret, &list, copier.Option{IgnoreEmpty: true, DeepCopy: true, Converters: []copier.TypeConverter{converters.ObjectIdToStringConverter(), converters.TimeToInt64()}})
	if err != nil {
		return nil, err
	}

	return &types.Get{{.serviceName}}ListResp{
		Total: total,
		List:  ret,
	}, nil{{end}}
}
