# 卡片背面：按学习内容组织阅读

## 已实现

- 单词：首屏合并核心释义、英文解释、双语例句和常用句型；搭配与词形、辨析、扩展通过命名页签访问。只为有实际内容的分节提供入口。
- 同一结构化单词在普通学习卡与生成卡中使用同一背面。兼容只有释义/例句 sections 的旧生成卡；无法识别的自定义内容完整保留。自定义背面规则优先，例如“只显示例句”不会展示被排除的释义。
- 词头作为紧凑身份区，核心答案作为主视觉；长词不再单行淡出。标题、元信息和正文一同滚动，放大文字时仍能读全。
- 通用题目卡突出当前分节的答案，不再在每一页重复固定的大号核心标题。页签明确表示当前内容，保留横向手势和底部翻页按钮。
- 诗词按行呈现；译文有明确逐行对应且行数一致时，原句下方呈现对应译文。行数不一致时保留完整独立译文页，避免错误配对或丢失文字。
- 双调词支持明确的“上阕 / 下阕”页签。生成契约使用上阕、下阕、上阕释义、下阕释义四个语义块；阅读层配对成两页。边界不明确时不猜测、不按字数平分，也不把所有宋代作品当作双调词。
- 字词注释按行或【词语】边界分项；长内容显示继续阅读提示及滚动条。
- 聊天预览使用适配高度并提供“展开阅读”入口；卡外导航明确标注上一张/下一张，与卡内章节切换区分。
- 生成规则补充单词释义、双语例句、常用句型、常见搭配和适用词形的要求；不为凑信息量编造词源或不可靠辨析。

## 数据与范围

`reviewSections` 仅负责阅读分组，持久化、编辑和导出仍使用原有 `learningSections` 契约。没有迁移或改写用户已保存的卡片。

旧卡可以直接受益于新版排版。旧卡中不存在的释义、搭配或逐句译文不会凭空补入；完整补充内容由后续生成提供。生成规则修改位于本地代码，未部署远端服务，也未调用模型重生成用户卡组。

## 验证

- Flutter 全量测试：177 项通过，包含原有学习手势、撤销、卡片编辑与存储测试。
- 新增覆盖：同页释义与例句、生成来源一致性、300 宽/420 高/双倍字号、逐句对应、上下阕切换、行数不匹配回退、旧卡中英例句分离、自定义排除规则、展开阅读、阅读分组不改变存储结构。
- `flutter analyze --no-pub`：无问题。
- Deno：`card_agent_test.ts` 与 `word_generation_test.ts` 共 19 项通过。
- iOS 18.5 模拟器：iPhone 16 Pro、iPad Pro 11-inch (M4)；每台设备深浅色各覆盖单词、诗词、宋词上下阕、双倍字号长词，共 20 张截图。使用固定内容验证布局，不把这些截图视为真实模型生成质量证明。
- 更新 5 张受影响的视觉基线；全量测试再次比对通过。

## 截图

| 场景 | iPhone | iPad |
|---|---|---|
| 单词首屏 | [浅色](card-back-redesign/iphone/light-word-back.png) · [深色](card-back-redesign/iphone/dark-word-back.png) | [浅色](card-back-redesign/ipad/light-word-back.png) · [深色](card-back-redesign/ipad/dark-word-back.png) |
| 逐句原文与译文 | [浅色](card-back-redesign/iphone/light-poem-back.png) · [深色](card-back-redesign/iphone/dark-poem-back.png) | [浅色](card-back-redesign/ipad/light-poem-back.png) · [深色](card-back-redesign/ipad/dark-poem-back.png) |
| 宋词上阕 | [浅色](card-back-redesign/iphone/light-ci-back.png) · [深色](card-back-redesign/iphone/dark-ci-back.png) | [浅色](card-back-redesign/ipad/light-ci-back.png) · [深色](card-back-redesign/ipad/dark-ci-back.png) |
| 宋词下阕 | [浅色](card-back-redesign/iphone/light-ci-lower.png) · [深色](card-back-redesign/iphone/dark-ci-lower.png) | [浅色](card-back-redesign/ipad/light-ci-lower.png) · [深色](card-back-redesign/ipad/dark-ci-lower.png) |
| 双倍字号长词 | [浅色](card-back-redesign/iphone/light-large-word-back.png) · [深色](card-back-redesign/iphone/dark-large-word-back.png) | [浅色](card-back-redesign/ipad/light-large-word-back.png) · [深色](card-back-redesign/ipad/dark-large-word-back.png) |

聊天预览的中文字体回退及展开入口见 [视觉基线](../../apps/mobile/test/goldens/21-agent-chat-back.png)。
