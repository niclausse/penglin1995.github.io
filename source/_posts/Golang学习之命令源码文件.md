---
title: Golang学习之命令源码文件
date: 2019-03-07 09:43:34
tags: Go
categories: go
---
## 一、概念
Go语言中，源码文件分为命令源码文件、库源码文件和测试源码文件三种，他们有着不同的用途和编写规则。

本篇中介绍命令源码文件：如果一个源码文件声明属于main包，并且包含一个无接收参数和无返回参数的main函数，那么他就是命令源码文件。如：

```go
package main

import "fmt"

func main() {
	fmt.Println("hello world!")
}
```
将以上代码保存到demo.go中，那么demo.go即为命令源码文件。

## 二、命令源码文件
### 1、命令源码文件接收和解析参数
```go
package main 

import (
	"fmt"
	"flag" //flag包专门用来接收和解析命令参数
)

var name string

func init() {
	flag.StringVar(&name, "name", "everyone", "The greeting object.")
	
}

func main() {
	flag.Parse() // 解析命令行参数
	fmt.Printf("Hello, %s!\n",name)
}
```

### 2、运行命令源码文件时传入参数，及查看参数说明
将上述代码保存为demo1.go，执行以下命令进行传参：

```sh
go run demo1.go -name="linpeng"
```
运行后，输出Hello,linpeng。

查看参数说明，运行`go run demo1.go --help`

### 3	、自定义命令源码文件的参数使用说明
有很多方式，最简单是对变量flag.Usage重新赋值。flag.Usage的类型是func，是一种无参数和无结果声明的函数类型。

flag.Usage变量在声明时已经被赋值了，所以在运行go run demo1.go --help时能看到正确的结果。

注意，对flag.Usage的赋值必须在flag.Parse()之前。

现在，把 demo2.go 另存为 demo3.go，然后在main函数体的开始出加入以下代码：

```go 
flag.Usage = func() {
 fmt.Fprintf(os.Stderr, "Usage of %s:\n", "question")
 flag.PrintDefaults()
}
```
运行go run demo2.go --help时，即可看到自定义说明。
