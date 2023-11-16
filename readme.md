# go-zero

基于源代码修改，新增了自动生成 API 增删改查逻辑，修改了 mongoDB 的代码逻辑；

1.使代码中可基于 SQL 语句的方式生成 bson 结构的 filter, options，减少代码编写，使条件查询更清晰
2.新增了自动生成 API 增删改查逻辑

#### 使用方法：

该源码为 go-zero 1.5.4 源码，默认会使用 1.5.4 的 tpl 文件, 这个文件请使用以下方法复制过去：

```shell
mkdir /workspace
mkdir ~/.goctl
cd /workspace
git clone git@github.com:pywee/go-zero.git
cd go-zero
ln -s /workspace/go-zero/goctl ~/.goctl/1.5.4 # 此处的源目录必须用绝对路径 /workspace/go-zero/goctl
```

编译 go-zero 的 goctl，主机内存如果小于8GB，在编译时可能会报错
```shell
cd tools/goctl
make

# 替换 GOPATH 目录下旧的 goctl
mv goctl 你的GOPATH/bin目录下的goctl
```

经过以上两步即可完成对 goctl 的替换。

---


#### 在你的项目中使用新的 goctl 和 SQL 语法

1.升级你项目中的 gobson-where 包，指定版本为 latest 即可
```go
github.com/pywee/gobson-where latest
```


#### 多个项目下使用的 Makefile
```
name ?= user
model ?= points
table ?= points_record

run:
	cd api && go run .

gen:
	rm -rf api/internal/types/types.go
	goctl api plugin -plugin goctl-swagger="swagger -filename ../../swagger.json" -api ./api/api/${name}.api -dir ./api/api/
	goctl api go -dir ./api -api ./api/api/${name}.api
	goctl model mysql datasource --cache="true" --url="root:xxx@tcp(ip:port)/dbName" --table="${table}" --dir ./mysqlModel

# goctl model mysql -c -e --dir ./model -t ${model}
```