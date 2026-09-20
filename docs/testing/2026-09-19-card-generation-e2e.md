# OCR 名称列表 → 内容补全 → 卡片生成：真实端到端测试

日期：2026-09-19。模型：OpenRouter `qwen/qwen3-vl-235b-a22b-instruct`。设备：iPhone 16 Pro，iOS 18.5。

本次从 OCR 后的文字列表开始，未向 Agent 提供诗词、古文原文。iOS 真实页面调用本地 Supabase CardAgent，再访问真实模型，执行聊天、生成、翻面、切卡和长卡滚动。相机及 OCR 本身不在本轮范围内，也未执行保存入库。线上 CardAgent 尚未部署，本结果不能视为线上环境验收。

## 结论

模型能够根据名称补齐内容，但目前还不能稳定地生成无需校对的卡片。最终一次“先选排版”路径完成 11 次真实接口调用，得到 11 张批量草稿和 1 张歧义题目的聊天预览；保存了 32 张原始模拟器截图。6 组场景中，人工内容评审为 2 组通过、2 组部分通过、2 组未通过。自动化的接口/原文检查与人工语义评审分别记录，不能用 Flutter 驱动完成来代表内容质量通过。

[查看全部正反面截图与原始回复](card-generation-e2e/index.html) · [原始请求和响应](card-generation-e2e/results.json) · [自动检查](card-generation-e2e/audit.json) · [人工评审](card-generation-e2e/review.json)

## 最终测试用例与结果

最终路径先通过真实 UI 选择排版，再发送要求并点击生成。下表耗时为该组聊天与生成接口耗时之和，不含编译、滚动或截图时间。

| 用例 | OCR 输入 / 要求 | 实际结果 | 内容结论 | 正反面截图 |
|---|---|---|---|---|
| W01 | borrow、lend、apple；补齐释义、音标、例句，正面仅单词 | 3 张；约 61.5 秒 | 部分通过。lend 出现“借出； lending”；部分搭配偏离目标义项 | [正面](card-generation-e2e/W01-1-front.png) / [背面](card-generation-e2e/W01-1-back.png) / [lend 问题](card-generation-e2e/W01-2-back.png) |
| P01 | 静夜思、春晓；每首一张全篇卡 | 2 张；约 21.2 秒 | 通过。作者正确，原文逐字核对完整，释义基本准确；诗行未分行 | [正面](card-generation-e2e/P01-1-front.png) / [背面](card-generation-e2e/P01-1-back.png) |
| P02 | 登鹳雀楼；补齐后做两联接句卡 | 2 张；约 53.9 秒 | 通过。两联完整、答案正确、无正面泄题，含释义 | [正面](card-generation-e2e/P02-1-front.png) / [背面](card-generation-e2e/P02-1-back.png) |
| C01 | 陋室铭、爱莲说；每篇一张，全文+翻译+字词 | 仅 1 张；约 51.3 秒 | 未通过。漏《爱莲说》并要求分批。《陋室铭》原文完整，但“白丁”的译文与注释语境义不一致 | [正面](card-generation-e2e/C01-1-front.png) / [背面顶部](card-generation-e2e/C01-1-back.png) / [背面底部](card-generation-e2e/C01-1-back-bottom.png) |
| C02 | 论语·学而第一则；补齐后逐句制卡 | 3 张；约 40.7 秒 | 部分通过。原句、翻译、yuè 读音正确，但把首句称为“陈述句” | [正面](card-generation-e2e/C02-1-front.png) / [背面](card-generation-e2e/C02-1-back.png) / [底部](card-generation-e2e/C02-1-back-bottom.png) |
| A01 | 送别；未指定作者 | 擅自生成 1 张聊天预览；约 5.9 秒 | 未通过。没有澄清，选了李叔同版本片段，作者缺失且原文不完整 | [实际回复](card-generation-e2e/A01-chat.png) |

## 自动路由和首次尝试

在默认单词规则下，诗词和古文有时切换成功，有时只要求用户手动确认并保持原规则，导致下一次点击生成返回空卡片；因此自动路由未通过。最终选排版的成功样本不能掩盖这一问题。

- [首轮记录](card-generation-e2e/first-run-results.json)：发现输出格式失败、栏目标签与内容错配、接句释义遗漏。
- [自动路由复测记录](card-generation-e2e/auto-routing-results.json)：单词预览超出张数限制被拒绝；诗词全篇和古文全篇保留单词规则而生成空结果；接句只覆盖前三句，漏末句。
- 最终采用明确选排版的正常用户路径。保留上述失败记录，没有改写模型输出，也没有用排版示例冒充生成结果。

## 本轮实现调整与验证

1. 诗词、古文 Skill 支持从可明确识别的篇目补齐作者、原文和解释，并区分 Agent 补全与 OCR 原文；同名/不确定作品应澄清。当前模型仍未稳定遵循歧义约束。
2. 增加显式选择 OpenRouter 的生成提供方配置；只有设置 `AI_PROVIDER=openrouter` 时启用，不会因为 OCR 已配密钥就自动改变生成服务。
3. 兼容完整 JSON 代码围栏，保留严格数据校验；按 action 限制聊天预览最多 1 张、生成最多 30 张。增加栏目语义说明和必要字段约束。
4. 共享后端测试 27 项通过；新增 iOS 驱动实际跑通页面流程，语义检查明确报出未通过项。
5. 最终保留 `skill_version=1` 的现有存储协议，避免原有保存 RPC 拒绝卡片。截图测试中间构建曾输出版本标记 2，未保存入库；恢复标记不更改生成内容，已用契约测试验证兼容。

没有部署线上。临时测试账号已清理，密钥没有写入报告或截图。

## 尚待解决

- 批次完整性：必须逐项核对输入篇目与输出卡片，不能漏篇还声称完成。
- 语义质量：词义/搭配一致性、中文释义纯净性、句式分析准确性需要进一步质量控制。
- 意图与状态：自动切换 Skill 不稳定；生成动作完成后，回复有时仍称预览并要求再次点击生成。
- 歧义处理：同名作品不能默认选择某一版本后输出片段。
- 视觉：诗词原文应按诗行分行；长古文全篇在 340px 聊天卡片中需要较多滚动，适合进一步提供展开阅读。

## 复现

在忽略的本地 env 文件中设置有效 OpenRouter 凭据、`AI_PROVIDER=openrouter` 和上述 `AI_MODEL`，启动 `supabase functions serve --env-file <本地env文件>`。然后执行：

```sh
python3 supabase/tests/card-agent/run_generation_ios.py --select-preset
python3 supabase/tests/card-agent/verify_generation_results.py
python3 supabase/tests/card-agent/build_generation_report.py
```

省略 `--select-preset` 可重测默认规则的自动切换路径。验证脚本发现未通过项会返回非零退出码。模型输出有随机性，本报告代表所记录的真实运行，不是稳定性概率评估。
