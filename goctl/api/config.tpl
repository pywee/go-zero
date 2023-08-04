package config

import {{.authImport}}
ww
type Config struct {
	rest.RestConf
	{{.auth}}
	{{.jwtTrans}}
}
