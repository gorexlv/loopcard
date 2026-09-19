# iOS OCR 自动化与视觉验证

环境：iPhone 16 Pro 模拟器、iOS 18.5。Flutter 集成测试运行真实生产页面和 OpenRouterTextRecognizer；仅替换相机、裁剪输入为三张清晰印刷测试图片。识别请求经过已部署的 Supabase photo-ocr 和真实 OpenRouter Qwen3-VL，未模拟识别响应。

## 回归结果

| 测试 | 结果 | 范围 |
|---|---|---|
| Flutter 全量测试 | 118 项通过 | 包括既有视觉基准、卡片、OCR、多照片和会话测试 |
| Deno 后端测试 | 24 项通过 | OCR 输入约束、响应完整性、Card Agent 规则 |
| 本地数据库 | 62 项通过 | 保存、权限、元数据、幂等与文学 Skill |
| Flutter analyze | 通过 | 无静态分析问题 |

模拟器集成测试最终通过（34 秒，不含构建），共保存 13 张截图。测试账号和临时凭证配置已删除。前两次失败为测试脚本的列表定位与嵌套滚动问题，修正后整条测试重跑通过。

## 模拟器用例

| 编号 | 操作 | 验证结果（均通过） |
|---|---|---|
| IOS-01 | 打开素材页 | 明确显示云端上传提示；无素材不可提交 |
| IOS-02 | 连续输入单词、诗词、繁体古文三张图 | 实际识别成功、显示三张素材，保留繁体与换行 |
| IOS-03 | 打开校对并删减英文例句 | 文本可编辑并保存 |
| IOS-04 | 删除第一张素材 | 数量从 3 变为 2 |
| IOS-05 | 重拍诗词素材 | 重新请求 OCR，数量仍为 2 |
| IOS-06 | 提交素材 | 进入 Card Agent，传递的两份文本包含诗词和繁体古文 |
| IOS-07 | 依次选用四种文学方案、翻面 | 正反面直接在聊天消息内渲染，明确标识为排版示例 |

截图保存在本目录 `ios-ocr/`。文字校对、素材列表与诗词背面截图已进行目视检查：中文可读，按钮可达，卡片分区清楚，未发现 Flutter 布局溢出。较长的古文背面超过固定卡片视口，需要在卡片内部滚动，首屏不会显示全部段落。缩略图使用居中裁切，长横图只显示局部；可点击查看完整图片。

## 发现的问题与未覆盖项

1. **真实对话生成尚不可用**：线上项目的 `card-agent` 尚未部署，认证后的实际 HTTP 请求返回 404 `NOT_FOUND`。证据为 `ios-card-agent-availability.json`。排版示例是静态模板，不能据此宣称真实问答、卡片生成及线上保存通过。
2. **iOS 26 模拟器兼容性**：当前保留的 GoogleMLKit / MLImage / MLKitCommon / MLKitVision 不支持该模拟器要求的 arm64。iOS 18.5 已可构建运行。云端 OCR 已不依赖 ML Kit 推理，但旧原生依赖仍存在。
3. 模拟器不验证真实相机权限、对焦、裁剪系统 UI、模糊和反光；这些需要真机实拍。测试图不是实际拍摄照片。
4. 本轮使用独立测试入口直接打开生产页面，未覆盖首页、登录页和 onboarding 的整条 UI 导航；登录通过真实测试账号 API 完成。

## 复跑

先启动可用 iOS 18.5 模拟器，再运行：

```sh
python3 supabase/tests/ocr/run_ios_visual.py --device <simulator-uuid>
```

脚本创建独立的线上测试账号，使用被 Git 忽略的临时配置运行 Flutter 集成测试，并在退出时删除账号和配置。不会创建正式卡组，也不会把 OpenRouter 密钥写入 App。首次运行需要 Flutter/iOS 构建环境及已登录的 Supabase CLI。

## 截图索引

- [三张素材与真实 OCR](ios-ocr/02-three-photos-real-ocr.png)
- [校对弹窗](ios-ocr/03-edit-ocr.png)
- [重拍后两份素材](ios-ocr/04-retake-two-photos.png)
- [进入生成对话](ios-ocr/05-chat-source-handoff.png)
- [诗词全篇背面](ios-ocr/06-preview-诗词全篇-back.png)
- [诗词接句背面](ios-ocr/06-preview-诗词接句-back.png)
- [古文逐句背面](ios-ocr/06-preview-古文逐句-back.png)
- [古文字词背面](ios-ocr/06-preview-古文字词-back.png)
