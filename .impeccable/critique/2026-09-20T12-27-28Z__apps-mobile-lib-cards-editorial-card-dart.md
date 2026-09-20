---
target: 当前卡片背面设计
total_score: 22
max_score: 40
na_heuristics:
p0_count: 0
p1_count: 3
target_identity: "file:/Users/rexlv/Workspace/github.com/gorexlv/loopcard/apps/mobile/lib/cards/editorial_card.dart"
target_fingerprint: "sha256:b5714fc89bf51413869f8ab3d65defc67435347c701681492ccd00f5f0172cbf"
target_path: /Users/rexlv/Workspace/github.com/gorexlv/loopcard/apps/mobile/lib/cards/editorial_card.dart
timestamp: 2026-09-20T12-27-28Z
slug: apps-mobile-lib-cards-editorial-card-dart
---
Method: dual-agent (A: /root/design_review · B: /root/visual_evidence)

审查日期：2026-09-20。范围：Flutter 卡片背面，涵盖普通单词、公式/题目、生成卡及文学卡，并检查学习页和聊天预览容器。审查当前工作区（含已有未提交改动），未修改产品代码。

核心结论：当前背面缺少统一的信息架构与空间预算。短内容过空，长内容成墙，同一知识因来源不同改变层级和导航；用户难以形成稳定的“核对答案—查看依据—评分”路径。玻璃背景已形成身份，但内容编排仍像字段输出。

## 证据与验证

独立设计审查先完成，才合并 detector 与测试结果。执行 impeccable detect --json apps/mobile/lib/cards，退出0、结果[]。detector为web-only，对Flutter没有有效覆盖，零发现不等于视觉通过。Native目标无DOM，因此无浏览器注入或overlay。

运行 flutter test --no-pub test/card_agent_visual_test.dart test/visual_golden_test.dart test/literary_card_test.dart test/editorial_card_test.dart --reporter expanded，17项通过，未更新golden。普通卡golden与当前实现匹配。文学截图结合当前源码使用；ios-ocr旧文学长列表不算当前证据；literary-pages里的<br>已由当前代码修复，不能报告为现存问题。未重启App采集新截图，未验证大字号/横屏/小屏全矩阵。

## 优先问题

### P1：短内容过度分页，空白没有服务学习任务

390×844截图中卡片高约616，内容结束与页脚之间约260空白，却将例句另放一页。study_screen.dart:474以宽×1.74决定卡高；editorial_card.dart:764的Expanded把页脚固定到底部；card_models.dart:174固定拆分释义与例句。

证据：apps/mobile/test/goldens/04-card-back.png、18-card-back-usage.png；docs/testing/glass-cards/light-study-back.png。

影响：高频复习每张卡都要为少量信息多翻一页，答案和用法无法就近核对。建议首屏保留核心答案与一条例句，辨析和扩展按需展开；固定卡壳内定义短、中、长内容布局。不是把所有资料塞回首屏。对应distill/layout。

### P1：同一种内容因来源不同而改变阅读规则

editorial_card.dart:44在presentation非空时直接转GeneratedCardFace，早于wordContent判断。普通borrow有词头、音标、发音与分页；生成borrow只有背面/释义/例句堆叠，英文例句和中文翻译可连在同一正文。generated_card_face.dart:107直接循环sections，缺少独立例句与译文角色。

证据：goldens/04-card-back.png对照docs/testing/card-generation-e2e/W01-1-back.png及goldens/21-agent-chat-back.png。

影响：扫读习惯失效，学习对象本身甚至不出现在生成卡背面。建议按单词、文学、题目解析选择统一组件，将生成来源与渲染结构解耦。对应shape/typeset。

### P1：文学长文缺少语义分组，固定预览高度进一步放大问题

generated_card_face.dart:295–338把正文放进单一Text，18字号、1.7行高。card_agent_screen.dart:639固定340高度，扣除边距、标题和页脚，正文约显示七行。原文、译文和字词解释缺少句段对应；词条靠括号混在连续段落中。

证据：docs/testing/literary-pages/L02-1-back-page-2.png、L02-1-back-page-3.png。末行被视口截开是正常可滚动区域，不是RenderFlex溢出。

影响：用户难以找到忘记的句子或词义；要同时理解横向章节和纵向正文。建议原文按句读、译文按对应段、注释按“词—读音—释义”分组。预览提供展开阅读入口与剩余内容提示，不用缩小字体解决。对应typeset/layout/clarify。

### P2：视觉权重偏向重复身份，未始终突出当前答案

editorial_card.dart:681词头34/w800强于释义25/28；677限制单行fade，同排还预留48发音按钮。普通题目在1063固定显示core.heading，使后续章节成为附属。短内容时大词头与大答案形成双主标题；长词可能被截去词尾，这是源码风险而非已复现截图缺陷。

建议词头缩为紧凑身份区，核心答案/当前要点成为主视觉；英文例句与中文译文独立层级；长词完整换行。保留当前玻璃材质即可，先处理字号、字重和间距。对应typeset/adapt。

### P2：导航表达页数，未表达信息结构

editorial_card.dart:1439只有解释1/3；generated_card_face.dart:343只有文学页码与箭头。聊天卡内切页和卡外切卡使用相似chevron（card_agent_screen.dart:656）。SingleChildScrollView未提供明显继续阅读信号。study_screen.dart:510已有长文滚动与评分隔离，不能指控一定误评分；但竖向手势用途变化不够直观。

建议用释义/例句/辨析或原文/译文/注释显示当前分节；切卡和切页使用不同语义标签；长页显示继续阅读信号。评分按钮保持一致，手势只做辅助。对应clarify/layout。

## 优点与设计特征

浅深模式材质统一、正文较安静；普通卡中释义与辅助说明已有基本层次；发音位置合理；普通分页48目标、语义标签、live region及减少动态效果适配已有实现。无需用更多装饰修复结构问题。未测量当前全部组合对比度，不声称不达标。

## Nielsen启发式评分

| 维度 | 分数/4 | 主要依据 |
|---|---:|---|
| 状态可见 | 3 | 页码明确，剩余正文不明确 |
| 符合真实任务 | 2 | 核对答案路径不稳定 |
| 用户控制 | 3 | 翻回、切页、评分及撤销 |
| 一致性 | 1 | 同内容不同渲染结构 |
| 错误预防 | 3 | 滚动评分已有隔离 |
| 识别优于记忆 | 2 | 分节需探索 |
| 效率 | 2 | 短卡多余翻页 |
| 美观与简洁 | 1 | 短卡过空、长卡成墙 |
| 错误恢复 | 3 | 评分可撤销 |
| 帮助与说明 | 2 | 导航与手势提示不足 |
| 总分 | 22/40 | 可用，需要显著改进 |

评分为设计启发式判断，非用户实验。没有明确单决策点超过4选项的证据；负担主要来自分组、层级、上下文记忆及渐进展示不一致。翻面应快速确认，当前容易变成寻找和探索。

## 场景与次要观察

高频复习者受额外翻页影响；新用户要猜分节内容并区分两组箭头；大字号用户面临单行词头和固定顶部空间的适配风险。元信息11–13字号应在大字号测试中核实；不能把显式fontSize误解为禁用系统字体缩放。

## 后续设计问题

1. 背面默认任务：快速核对答案（推荐），还是完整阅读讲义？
2. 优先审定的模板：单词背面（推荐），还是诗词/古文背面？

建议先确定内容层次与模板，再统一渲染分支，最后调整字体、间距、材质；验收覆盖短/中/长内容与放大文字。未实施设计修改。
