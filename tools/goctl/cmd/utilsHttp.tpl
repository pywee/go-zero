package utils

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"strings"
)

// GetClientIP 获取客户端IP
// 只需要公网
func GetClientIP(r *http.Request) string {
	// 1. 检查 X-Forwarded-For 头
	if xff := r.Header.Get("X-Forwarded-For"); xff != "" {
		// X-Forwarded-For 可能包含多个 IP，取第一个非空的
		ips := strings.Split(xff, ",")
		for _, ip := range ips {
			ip = strings.TrimSpace(ip)
			if nip := net.ParseIP(ip); nip != nil {
				return ip
			}
		}
	}

	// 2. 检查 X-Real-IP 头
	xRealIP := r.Header.Get("X-Real-IP")
	if nip := net.ParseIP(xRealIP); nip != nil {
		if idx := strings.Index(xRealIP, "/"); idx != -1 {
			return xRealIP[:idx]
		}
		return xRealIP
	}

	// 3. 直接从 RemoteAddr 获取
	ip, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		return ""
	}
	if nip := net.ParseIP(ip); nip != nil {
		if idx := strings.Index(ip, "/"); idx != -1 {
			return ip[:idx]
		}
		return ip
	}
	return ""
}

// isPublicIP 是否公网IP
func isPublicIP(ip net.IP) bool {
	if ip.IsLoopback() || ip.IsPrivate() || ip.IsUnspecified() {
		return false
	}
	return true
}

// PostJSON
func PostJSON(token, url string, payload any) ([]byte, error) {
	data, err := json.Marshal(payload)
	if err != nil {
		return nil, fmt.Errorf("JSON 编码失败: %w", err)
	}

	req, err := http.NewRequest("POST", url, bytes.NewBuffer(data))
	if err != nil {
		return nil, fmt.Errorf("创建请求失败: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("请求失败: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("读取响应失败: %w", err)
	}

	if resp.StatusCode > 200 {
		return nil, fmt.Errorf("请求返回错误状态码: %d, 内容: %s", resp.StatusCode, string(body))
	}

	return body, nil
}

// HttpGet 发起 GET 请求
func HttpGet(surl string) ([]byte, error) {
	req, err := http.NewRequest("GET", surl, nil)
	if err != nil {
		return nil, err
	}

	var referer string
	purl, _ := url.Parse(surl)
	if purl.Scheme != "" {
		referer = purl.Scheme + "://" + purl.Host
	}

	// 添加模拟浏览器的头部信息
	req.Header.Set("Referer", referer)
	req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36")
	req.Header.Set("Accept", "image/webp,image/apng,image/*,*/*;q=0.8")
	req.Header.Set("Accept-Language", "en-US,en;q=0.9")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("请求失败: %s", resp.Status)
	}

	// out, _ := os.Create("xxx.jpeg")
	// io.Copy(out, resp.Body)

	return io.ReadAll(resp.Body)
}
