package model

// Exec 原生执行语句
func (m *customOrderModel) Exec(sql string, args ...any) error {
	if err := m.c.Exec(sql, args...).Error; err != nil {
		return err
	}
	return nil
}

// Query 原生查询语句
func (m *customOrderModel) Query(ret any, sql string, args ...any) error {
	return m.c.Raw(sql, args...).Scan(&ret).Error
}