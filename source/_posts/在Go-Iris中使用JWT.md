---
title: 在Go Iris中使用JWT</br>
date: 2019-11-04 13:55:04</br>
tags: 技术</br>
categories: go

---
## 跨域认证
互联网服务离不开用户认证，一种认证方式是：

1、 用户向服务器发送用户名和密码；</br>
2、 服务器认证通过后，在当前会话(session)中保存相关数据，比如用户角色、登录时间等；</br>
3、 服务器向用户返回一个session_id，写入用户的Cookie；</br>
4、 用户随后的每一次请求，都会通过Cookie，将session_id传回服务器；</br>
5、 服务器收到session_id，找到前期保存的数据，由此得知用户的身份。

## 关于JWT
JSON Web Token（JWT）是一个开放标准（RFC 7519），它定义了一种紧凑且独立的方式，可以在各方之间作为json对象安全地传输信息。此信息可以通过数字签名进行验证和信任。JWT可以使用秘密或者使用RSA或ECDSA的公钥/私钥对进行签名。

JWT的原理是，服务器认证后，生成一个JSON对象，发回给用户，就像下面这样。

```json
{
	"name": name, 
	"exp": time.Now().Add(time.Hour * 2).Unix()
}
```

以后，用户与服务端通信的时候，都要发回这个JSON对象。服务器完全只靠这个对象认定用户的身份。为了防止用户篡改数据，服务器再生成这个对象的时候，会加上签名。

服务器就不保存任何session数据了，也就是说，服务器变成无状态了，从而比较容易实现扩展。

实际的JWT大概就像下面这样：

```bash
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE1NTk4MDMyODEsInBhc3N3b3JkIjoiMTIzMyIsInBob25lIjoiMTU5MDIwMTUwNDMifQ.NvKsiKh37pxmRH4inKb32EXT-XkSfIC96nEX7p1RLag

```

它是一个很长的字符串，中间用点（.）分隔成三个部分： Header.Payload.Signature

* Header（头部）：一个JSON对象，描述JWT的元数据，一般如下所示：

```	json
{
	"alg": "HS256",
	"type": "JWT"
}
```
`alg`属性表示签名的算法（algorithm），默认是HMAC SHA256（HS256）；`type`属性表示这个令牌（token）的类型，JWT令牌统一写为JWT。最后，将上面的JSON对象使用Base64URL算法转成字符串。

* Payload（负载）：也是一个JSON对象，用来存放实际需要传递的数据，例如：

```json
{
	"sub": "1234567890",
	"name": "John Doe",
	"admin": true
}
```

同样，Payload经过Base64URL编码，形成JSON Web Token的第二部分，数据虽然不可篡改，但是确实透明的。

* Signature（签名）：对前两部分的签名，防止数据篡改；首先，需要指定一个密钥（secret）。这个密钥只有服务器才知道，不能泄露给用户。然后，使用Header里面指定的签名算法，按照下面的公式产生签名。

例如，如果要使用HMAC SHA256算法，将按以下方式创建签名：

```bash
HMACSHA256(
	base64UrlEncode(header) + "." + 
	base64UrlEncode(payload),
	secret
)
```

签名用于验证消息在此过程中未被修改，并且，在使用私钥签名的令牌的情况下，它还可以验证JWT的发件人是否是它所声称的人。

需要注意的是，使用签名Token，Token中包含的所有信息都会向用户或其他方公开，即使他们无法更改。这意味着不应该在`Token`中放置秘密信息。

## JWT的工作原理
在身份验证中，当用户使用其凭据成功登录时，将返回JSON Web Token。由于Token是凭证，因此必须非常小心防止出现安全问题。一般情况下，你不应该将令牌保留的时间超过要求。