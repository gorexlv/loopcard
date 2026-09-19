# OpenRouter Qwen3-VL OCR 接入

模型固定为 `qwen/qwen3-vl-235b-a22b-instruct`，支持图片输入，已通过 OpenRouter 模型目录确认。

App 拍照和裁剪后，经登录态调用 Supabase `photo-ocr`，后端再调用 OpenRouter。密钥存于 Supabase Secrets 和被 Git 忽略、权限 0600 的本地服务端环境文件，未进入 Flutter 配置。原有本地 ML Kit 实现保留，App 主入口改用云端识别器。

识别页明确提示上传云端；照片逐张识别，保留校对、删减、重拍和失败重试。后端不持久化图片，图片会发送到 OpenRouter 及其模型服务商。文本保留繁简体、标点、分行，无法辨认处要求输出 `〔不清〕`。不在 OCR 阶段翻译、解释或按记忆补全原文。

接口约束：登录用户、JPEG/PNG/WebP、最大 5 MiB、实际文件头校验、禁止任意远程图片 URL、55 秒上游超时、拒绝 token 截断结果。客户端最多等待 65 秒。云端故障显示失败并保留照片，不悄悄换模型。

## 实际模型调用

用 Pillow 排版生成三个清晰印刷测试图，经过本地 Edge Function 到真实 OpenRouter API：

| 用例 | 检查点 | 结果 | 耗时 |
|---|---|---|---|
| 英文单词及中文释义 | 大小写、标点、中英混排 | 全文逐字一致 | 2.45 秒 |
| 《静夜思》 | 作者、原文、标点、诗句换行 | 全文逐字一致 | 1.85 秒 |
| 繁体《论语》及读音注释 | 繁体字、yuè、引号、换行 | 全文逐字一致 | 2.76 秒 |

这些是三张合成清晰图的结果，不能推算实拍准确率。未覆盖模糊、反光、书页弯曲、竖排、密集注释和复杂生僻字。实际输入、输出和耗时见 `openrouter-ocr-results.json`；线上复测见 `openrouter-ocr-hosted-results.json`。测试用户均在 finally 中删除。

复测：`python3 supabase/tests/ocr/live_smoke.py`。须安装 Pillow、具备中文字体，并运行本地 Supabase Edge Functions。显式传入 `--project-ref` 可测试指定线上项目，会创建并清理独立测试用户。

## 部署与回归

已部署到 App 默认连接的 `loopcard` 项目（hzntwddwaayzrgbwprif）。线上三个样本逐字一致，耗时分别为 3.38、2.16、2.24 秒；鉴权和非法图片请求校验通过。Deno 测试 24 项通过；Flutter 相关测试及 analyze 结果见本次执行记录。已安装旧 App 需重新构建安装才能切换识别器。

## 运维

服务端变量：`OPENROUTER_API_KEY`、`OCR_MODEL`。本地 `supabase functions serve photo-ocr` 自动读取 `supabase/functions/.env`。线上使用 Secrets 设置并部署 `photo-ocr`；不要把密钥写进 `--dart-define`。

本次只配置 OCR 的 OpenRouter 访问，Card Agent 的生成模型配置保持原状。上线后可按实际调用量补充分用户额度和持久化限流；当前接口校验登录，但未实施每日使用配额。
