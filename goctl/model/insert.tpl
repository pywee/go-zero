func (m *default{{.upperStartCamelObject}}Model) Insert(ctx context.Context, data *{{.upperStartCamelObject}}) (sql.Result,error) {
	rv:=reflect.ValueOf(data)
	if rv.Elem().FieldByName("CreateTs").IsValid() {
		if data.CreateTs == 0  {
			data.CreateTs = time.Now().Unix()
		}
	}
	if rv.Elem().FieldByName("UpdateTs").IsValid() {
		if data.UpdateTs == 0  {
			data.UpdateTs = time.Now().Unix()
		}
	}
	
	{{if .withCache}}{{.keys}}
    ret, err := m.ExecCtx(ctx, func(ctx context.Context, conn sqlx.SqlConn) (result sql.Result, err error) {
		query := fmt.Sprintf("insert into %s (%s) values ({{.expression}})", m.table, {{.lowerStartCamelObject}}RowsExpectAutoSet)
		return conn.ExecCtx(ctx, query, {{.expressionValues}})
	}, {{.keyValues}}){{else}}query := fmt.Sprintf("insert into %s (%s) values ({{.expression}})", m.table, {{.lowerStartCamelObject}}RowsExpectAutoSet)
    ret,err:=m.conn.ExecCtx(ctx, query, {{.expressionValues}}){{end}}
	return ret,err
}
