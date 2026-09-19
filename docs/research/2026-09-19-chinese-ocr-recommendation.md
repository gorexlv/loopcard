# 中文 OCR 选型建议（2026-09-19）

建议先为现有 ML Kit 接入中文随包模型，覆盖横排教材、诗词和古文拍照。把 PP-OCRv6 small 作为复杂材料的对照候选；只有真实样本显示收益足够时再承担新推理引擎的维护成本。本轮完成资料调研，未进行模型精度或真机性能横评，也未替换 OCR。

## 当前项目

Flutter 使用 google_mlkit_text_recognition 0.16.0，当前识别器为 Latin，原生工程没有中文识别依赖。已具备多张照片管理、OCR 后编辑与批量提交。增加诗词 Skill 不能自动使 OCR 支持中文：识别器必须单独接入。

| 方案 | 建议用途 | 接入成本判断 | 局限与待验证项 |
|---|---|---|---|
| ML Kit Text Recognition v2 中文（随包） | 第一选择：横排印刷教材、诗词、古文 | 低：复用现有 Flutter 包，补两端依赖和 script 选择 | 包体增量；竖排、生僻字、夹注与模糊照片需要样本验证 |
| PP-OCRv6 small | 复杂材料的第二候选；同时用 tiny 做资源基线 | 中高：模型、前后处理、推理运行时、Flutter 原生桥接 | Android 有官方部署示例，iOS 不能假定同样即插即用；需测整条检测与识别流水线 |
| 百度智能云通用文字识别高精度 | 可选的联网困难照片补救 | 中：后端代理、鉴权、费用与失败重试 | 图片离开设备，需要明确用户选择；网络耗时与按量成本 |

ML Kit 官方明确支持中文及文本块、行与位置结构；这是能力说明，不代表在本项目诗词样本上已经达到特定准确率。[官方概览](https://developers.google.com/ml-kit/vision/text-recognition/v2)

Paddle 官方已提供 PP-OCRv6 及多种规模模型，因此不把 v5 当成最新方案。v6 small 是建议参与横评的起点，最终选择应由同一批照片上的质量与设备预算决定。[PP-OCRv6 官方资料](https://github.com/PaddlePaddle/PaddleOCR/blob/main/docs/version3.x/algorithm/PP-OCRv6/PP-OCRv6.md)

百度提供高精度中文 OCR，可评估生僻字等困难材料；不直接采用营销准确率作为本产品指标。[官方产品说明](https://ai.baidu.com/tech/ocr/general)

## 首选方案的落地范围

1. Android 添加中文随包识别依赖；iOS 添加 TextRecognitionChinese Pod；Dart 使用 `TextRecognitionScript.chinese`，保留英语场景的 Latin 识别选择。中文、英文混排和拼音必须另测。
2. 优先随包模型，使首次离线使用无需等待模型下载。Google 文档列出 Android 随包方案每种 script、每种架构约 4 MB；iOS 每种 script SDK 约 38 MB。最终安装包增量须通过实际构建比较，不能把这些数字当作 App 下载体积。
3. 核对 Android 最低系统版本：当前 Google 文档要求 API 23，Flutter 包旧说明存在版本差异，应以选定原生依赖的构建要求为准。现有 iOS 15.5 配置满足当前 Flutter 包说明。
4. 保存原文行序和分段；下一步若支持竖排，识别结果接口应保留 bounding boxes，而不只返回字符串列表。不要让 Card Agent 悄悄把疑似 OCR 错字替换为记忆中的古诗版本。
5. 测中文模型初始化失败、连续 10 张照片、重拍删除后的顺序、识别器释放和首次离线启动。

依据：[Android 官方接入](https://developers.google.com/ml-kit/vision/text-recognition/v2/android)、[iOS 官方接入](https://developers.google.com/ml-kit/vision/text-recognition/v2/ios)、[项目所用 Flutter 包 0.16.0](https://pub.dev/packages/google_mlkit_text_recognition/versions/0.16.0)。Flutter 包由社区维护，并非 Google 官方 Flutter SDK。

PP-OCRv6 的 Android 官方示例采用 ONNX Runtime，提供 AAR 集成路径，示例要求 minSdk 26、JDK 17。选择该路径前需确认不会意外缩小当前支持设备范围，iOS 工程单独估算。[官方 Android 部署说明](https://github.com/PaddlePaddle/PaddleOCR/blob/main/docs/version3.x/inference_deployment/cross_platform/android_deployment.md)

## 建议的对照测试（尚未执行）

准备 100 张有人工校对真值的真实照片，每类 20 张：横排诗词、横排古文含注释、繁体竖排、生僻字与拼音混排、低光/倾斜/手写。记录字符错误率 CER（含标点与不含标点各一份）、关键古字错误、阅读顺序、分段保真、P50/P95 延迟、峰值内存、安装包增量、10 张批处理稳定性。至少覆盖一台中低端 Android 和一台 iPhone。

清晰横排印刷材料可暂以 CER ≤ 1% 作为产品验收目标；这是建议目标，非已测结论。古字、作者、句序错误单独记录，避免整体平均分掩盖卡片学习风险。困难样本保留用户校对入口；云识别需显式选择，并且密钥只放在服务端。
