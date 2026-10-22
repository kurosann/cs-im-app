# CS-IM · App（V1 移动端）

聚合客服系统 V1 移动值守客户端，按原型 `/mobile`（V1）实现：**移动值守、会话沟通、状态查看、个人设置**。

> 文档入口：[docs/README.md](docs/README.md)（计划 / 方案 / 规则 / AI 产物 / 历史 / 素材）

## 当前范围（V1）

- 值守：30 条 Mock 会话，支持筛选（全部 / 待人工 / AI / 人工）、未读角标、未回复标识、头像右下角平台来源 logo；
- 聊天：客户 / AI / 客服消息气泡，文本发送（本地 Mock），右上角「…」查看客户信息，支持 Mock 双语翻译、输入框边写边译、图片/视频/语音消息展示、悬浮毛玻璃输入区、图片/视频/文件附件入口；
- 状态：值守概况（待人工 / 处理中 / AI 已处理）+ **业务渠道** / **转发渠道** 两个独立列表，展示平台 logo、账号与连接状态；
- 我的：账号个人信息 + 基础设置（外观 / 消息提醒 / 语言 / 隐私 / 存储空间 / 版本）；支持浅色 / 深色 / 跟随系统；
- 隐私与存储：隐私协议首屏说明「收集什么 / 存储什么 / 如何加密 / 不会用于第三方」；存储空间展示本地缓存分类、512 MB 上限与《存储协议》，支持 Mock 清理；
- 字体：全局使用 Inter，中文通过 Noto Sans SC 回退；翻译设置中的标题、字段和选项统一字号与字重；
- 翻译：开启后会对所有文本消息实时调用机器翻译，Mock 消息同样生效；
- 设置持久化：主题、消息提醒、翻译开关与语言设置通过 `shared_preferences` 保存；
- 数据：默认 Mock 演示；远程模式通过 `AppStore` → `ChatRepository` → `RemoteChatRepository` 对接 cs-im-server。

> V1 的本地缓存统计与清理为 Mock 状态，真实文件统计、自动清理与本地删除待接入；隐私协议与存储协议为原型草案，上线前需法务审核。

## 开发

验证工具链：Flutter 3.47.7 / Dart 3.13.5。

```sh
flutter pub get
flutter run -d chrome     # 或 android / ios
flutter analyze
flutter test
```

接入 cs-im-server 的 `vecor` 分支时关闭 Mock，使用管理员分配的工作台账号或邮箱及密码登录。账号需具备 `gateway:admin` 权限；客服消息的 `sender.id` 使用登录结果中的 `userKey`。

```sh
flutter run --dart-define=CS_IM_USE_MOCK=false --dart-define=CS_IM_API_BASE=http://127.0.0.1:19091
```

远程模式对接：

- 登录、会话验证和登出：`/api/v1/auth/login`、`/api/v1/auth/me`、`/api/v1/auth/logout`。密码和会话 Token 只在内存中使用，退出时清空工作区数据并请求撤销 Token。
- 值守：读取 `/admin/v1/conversations` 的 `items/total` 分页、服务端未读数及回复状态，每 8 秒刷新会话与消息，展示 AI 回复；通过 `/admin/v1/conversations/:id/read` 标记已读。
- 消息和渠道：使用 `/admin/v1` 下的消息、业务 App、转发渠道接口。文本消息和 http(s) 媒体地址可以发送；文件上传与语音发送仍需后端支持。
- 翻译：「自动」优先请求 `/api/v1/translations`，失败时使用 `/admin/v1/translate`（LLM / Google），仍失败时使用客户端翻译。手动选择翻译源时沿用客户端测速和回退。自动目标语言按中英文方向转换为具体语言代码。

可通过 `--dart-define=CS_IM_OPERATOR_ID=账号或邮箱` 预填账号。开发时请使用实际可访问的服务器地址；Android 模拟器访问宿主机通常使用 `10.0.2.2`。

## 目录

```text
lib/
├── app.dart              # MaterialApp 与全局 AppStore
├── config/               # apiBaseUrl / useMockData
├── data/                 # ChatRepository + Mock + Remote
├── models/               # Conversation / ChatMessage
├── screens/              # 值守 / 聊天 / 状态 / 我的 / 隐私 / 存储
├── state/                # AppStore + AppScope
├── theme/                # 原型色板与 ThemeData
└── widgets/              # 会话列表项与协议卡片
```

