package main

import (
	"encoding/json"
	"fmt"
)

// 如果`json:"code"`去掉.会以字段名称为解析内容
type Result struct {
	Code    *int64 `json:"Code"`
	Code2   int64  `json:"Code2"`
	Message string `json:"msg"`
}

func main() {
	var res Result
	if res.Code == nil {
		res.Code2 = -1
		fmt.Println("xxxxxxxxxxxxxxxx1111")
	} else {
		res.Code2 = *res.Code
		fmt.Println("xxxxxxxxxxxxxxxx2222")
	}
	res.Message = "success"

	jsons, errs := json.Marshal(res)
	if errs != nil {
		fmt.Println("json marshal error:", errs)
	}
	fmt.Println("json data :", string(jsons))
	var str1 string
	fmt.Println("---xxxxx----", str1 == "")
	str2 := []string{"aa", "bb"}
	fmt.Println("xx--sdfadfa---", len(str2))

	var str3 string
	fmt.Println("==========xxx===", str3)
}
