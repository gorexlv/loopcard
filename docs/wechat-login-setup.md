# 微信登录配置

LoopCard 已接入 `fluwx_no_pay 6.0.2`，客户端请求 `snsapi_userinfo` 授权并取得一次性 code。完整账号登录仍需服务端使用 code 换取微信 access token 和用户资料；AppSecret 不得放入 Flutter 客户端。

## 当前 Android 测试应用

- Android 包名：`com.loopcard.loopcard`
- 当前签名 MD5：`f0bc8c55a00cd5eb3ef00708afdea1fa`
- 当前签名 SHA1：`F2:F9:B1:77:C2:18:0E:12:77:E1:69:7B:2E:FA:9A:F1:35:26:27:BE`

当前 Release APK 仍使用开发机 debug keystore。可用上述包名和 MD5 在微信开放平台配置测试；正式发布前应创建独立 release keystore，并把正式签名重新登记到微信开放平台。

## 环境变量

复制 `.env.example` 中以下配置到本机 `.env`：

```dotenv
WECHAT_APP_ID=微信开放平台移动应用AppID
WECHAT_UNIVERSAL_LINK=https://example.com/wechat/ios/
WECHAT_AUTH_ENDPOINT=https://api.example.com/auth/wechat/mobile
```

Android 不使用 Universal Link，但保留该配置供 iOS。`WECHAT_AUTH_ENDPOINT` 接收：

```json
{"code":"微信返回的一次性授权码"}
```

成功响应支持以下结构：

```json
{
  "user": {
    "id": "内部用户ID",
    "nickname": "用户昵称",
    "avatar_url": "https://example.com/avatar.jpg"
  }
}
```

## iOS 额外要求

iOS 还需在微信开放平台登记 Bundle ID 与 Universal Link，并配置 Associated Domains、微信 URL Scheme 和查询 Scheme。当前 Flutter 代码已经向 SDK 传递 `WECHAT_UNIVERSAL_LINK`，原生平台登记需在获得正式 AppID 和域名后完成。
