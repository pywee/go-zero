package cmd

import (
	_ "embed"
	"errors"
	"fmt"
	"os"
	"runtime"
	"strings"
	"text/template"

	"github.com/gookit/color"
	"github.com/spf13/cobra"
	cobracompletefig "github.com/withfig/autocomplete-tools/integrations/cobra"
	"github.com/zeromicro/go-zero/tools/goctl/api"
	"github.com/zeromicro/go-zero/tools/goctl/bug"
	"github.com/zeromicro/go-zero/tools/goctl/docker"
	"github.com/zeromicro/go-zero/tools/goctl/env"
	"github.com/zeromicro/go-zero/tools/goctl/gateway"
	"github.com/zeromicro/go-zero/tools/goctl/internal/cobrax"
	"github.com/zeromicro/go-zero/tools/goctl/internal/version"
	"github.com/zeromicro/go-zero/tools/goctl/kube"
	"github.com/zeromicro/go-zero/tools/goctl/migrate"
	"github.com/zeromicro/go-zero/tools/goctl/model"
	"github.com/zeromicro/go-zero/tools/goctl/quickstart"
	"github.com/zeromicro/go-zero/tools/goctl/rpc"
	"github.com/zeromicro/go-zero/tools/goctl/tpl"
	"github.com/zeromicro/go-zero/tools/goctl/upgrade"
)

const (
	codeFailure = 1
	dash        = "-"
	doubleDash  = "--"
	assign      = "="
)

var (
	//go:embed utilsStr.tpl
	utilsStrTpl string
	//go:embed usage.tpl
	usageTpl string
	//go:embed utils.tpl
	utilsTpl string
	//go:embed utilsHttp.tpl
	utilsHttpTpl string
	//go:embed utilsRand.tpl
	utilsRandTpl string
	//go:embed utilsTime.tpl
	utilsTimeTpl string
	//go:embed resp.tpl
	respTpl string
	//go:embed redis_cache.tpl
	cacheTpl string
	//go:embed redis_init.tpl
	cacheInitTpl string
	//go:embed redis_set.tpl
	cacheSetTpl string
	//go:embed redis_key.tpl
	cacheKeyTpl string
	//go:embed redis_list.tpl
	cacheListTpl string
	//go:embed redis_sorted.tpl
	cacheSortedTpl string
	//go:embed redis_string.tpl
	cacheStringTpl string
	//go:embed redis_hash.tpl
	cacheHashTpl string

	rootCmd = cobrax.NewCommand("goctl")
)

// Execute executes the given command
func Execute() {
	os.Args = supportGoStdFlag(os.Args)
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(color.Red.Render(err.Error()))
		os.Exit(codeFailure)
	}
}

func supportGoStdFlag(args []string) []string {
	copyArgs := append([]string(nil), args...)
	parentCmd, _, err := rootCmd.Traverse(args[:1])
	if err != nil { // ignore it to let cobra handle the error.
		return copyArgs
	}

	for idx, arg := range copyArgs[0:] {
		parentCmd, _, err = parentCmd.Traverse([]string{arg})
		if err != nil { // ignore it to let cobra handle the error.
			break
		}
		if !strings.HasPrefix(arg, dash) {
			continue
		}

		flagExpr := strings.TrimPrefix(arg, doubleDash)
		flagExpr = strings.TrimPrefix(flagExpr, dash)
		flagName, flagValue := flagExpr, ""
		assignIndex := strings.Index(flagExpr, assign)
		if assignIndex > 0 {
			flagName = flagExpr[:assignIndex]
			flagValue = flagExpr[assignIndex:]
		}

		if !isBuiltin(flagName) {
			// The method Flag can only match the user custom flags.
			f := parentCmd.Flag(flagName)
			if f == nil {
				continue
			}
			if f.Shorthand == flagName {
				continue
			}
		}

		goStyleFlag := doubleDash + flagName
		if assignIndex > 0 {
			goStyleFlag += flagValue
		}

		copyArgs[idx] = goStyleFlag
	}
	return copyArgs
}

func isBuiltin(name string) bool {
	return name == "version" || name == "help"
}

func init() {
	cobra.AddTemplateFuncs(template.FuncMap{
		"blue":    blue,
		"green":   green,
		"rpadx":   rpadx,
		"rainbow": rainbow,
	})

	rootCmd.Version = fmt.Sprintf(
		"%s %s/%s", version.BuildVersion,
		runtime.GOOS, runtime.GOARCH)

	rootCmd.SetUsageTemplate(usageTpl)
	rootCmd.AddCommand(api.Cmd, bug.Cmd, docker.Cmd, kube.Cmd, env.Cmd, gateway.Cmd, model.Cmd)
	rootCmd.AddCommand(migrate.Cmd, quickstart.Cmd, rpc.Cmd, tpl.Cmd, upgrade.Cmd)
	rootCmd.Command.AddCommand(cobracompletefig.CreateCompletionSpecCommand())

	createUtilFile()
	createCacheFile()
	rootCmd.MustInit()
}

func createUtilFile() error {
	c, _ := os.Getwd()
	if c == "" {
		return errors.New("can not find cache dir")
	}

	dir := c + "/utils"
	if !directoryExists(dir) {
		return os.Mkdir(dir, 0755)
	}

	files := map[string]string{
		"/utils.go": utilsTpl,
		"/time.go":  utilsTimeTpl,
		"/rand.go":  utilsRandTpl,
		"/http.go":  utilsHttpTpl,
		"/resp.go":  respTpl,
		"/str.go":   utilsStrTpl,
	}

	for path, file := range files {
		if fileExists(dir + path) {
			continue
		}
		if err := os.WriteFile(dir+path, []byte(file), 0666); err != nil {
			return err
		}
	}

	return nil
}

func createCacheFile() error {
	c, _ := os.Getwd()
	if c == "" {
		return errors.New("can not find cache dir")
	}
	dir := c + "/cache"
	if !directoryExists(dir) {
		return os.Mkdir(dir, 0755)
	}

	files := map[string]string{
		"/cache.go":        cacheTpl,
		"/init.go":         cacheInitTpl,
		"/redis_hash.go":   cacheHashTpl,
		"/redis_key.go":    cacheKeyTpl,
		"/redis_list.go":   cacheListTpl,
		"/redis_string.go": cacheStringTpl,
		"/redis_set.go":    cacheSetTpl,
		"/redis_sorted.go": cacheSortedTpl,
	}
	for path, file := range files {
		if fileExists(dir + path) {
			continue
		}
		if err := os.WriteFile(dir+path, []byte(file), 0666); err != nil {
			return err
		}
	}

	return nil
}

// fileExists checks if a file exists
func fileExists(path string) bool {
	info, err := os.Stat(path)
	if os.IsNotExist(err) {
		return false
	}
	if err != nil {
		return false
	}
	return !info.IsDir()
}

func directoryExists(path string) bool {
	info, err := os.Stat(path)
	if os.IsNotExist(err) {
		return false
	}
	if err != nil {
		return false
	}
	return info.IsDir()
}
