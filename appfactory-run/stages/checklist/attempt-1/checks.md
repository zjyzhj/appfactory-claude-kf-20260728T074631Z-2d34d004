# ThreadGrid · 验收清单(checks)

标准来源:PM `stages/pm_docs/attempt-1/MAP.md` + `build/*`;政策集 `agents/FinalGateAgent/direct-repo-required-checks.json`(policy_version 2.12.0)。
运行模式:**runtime_verification_required**——标注 `runtime_hard` 的 check 在 verification 阶段必须携带真实 iOS Simulator 证据(`ios_runtime_acceptance`:install/launch/screenshot/readback,hash-bound),仅靠源码审查不得判 pass。每条均给出:源码静默证明点(供 rough_app open-book 构建与 L0/L2)+ Simulator 行为复现路径(供 L1)。

PM ACC 锚点写法:`ACC-xxx` 见 `build/acceptance.md`;moment/slot 见 `build/design.md`。

---

## A. 政策 required set(17 条,顺序即评分顺序)

### 1. product_maturity:core_value_and_feature_completeness · runtime_hard
- **要求(zh)**:声明的核心价值与 F1–F12 每条能力都必须有可发现入口与端到端可走通旅程:创建(照片/相机/空白)→ 编辑 → 绣制 → 导出闭环。无占位控件、无静态 demo、无"只描述能力"的落地页。锚:build/product.md §核心回路;ACC-001…006、ACC-012、ACC-REV-COMPLETE。
- **源码静默证明**:Sources 中存在 4 tab 根视图与 route 命名表全部 route_id 对应视图;F2 色彩量化(中位切分或等价)为端上实现且无网络调用;F4 编辑器 undo 栈、F6 完工检测、F12 权限拒绝替代入口均有真实实现;无 `TODO`/placeholder 主流程。
- **Simulator 复现路径**:空库启动 → tab_charts 空态 → "Create your first chart" → create_wizard 相册选图 → 调尺寸/色数 → 预览 → 保存 → chart_detail → Edit 改色/撤销 → Start stitching → 标记格子 → (测试数据加速)完工 → chart_export。逐步截图 + readback。

### 2. product_maturity:feature_expansion
- **要求(zh)**:总是生成、总是消费。判定产品形态:ThreadGrid 声明 F1–F12(图样库/编辑器/绣制/线库/导出/IAP),倾向 already_mature;若判 simple_thin 则必须实现至少一个高价值 domain-native 扩展。already_ok 仅当证据证明核心任务生命周期完整、有回访价值(图样库 + 进度资产)、持久化与 empty/loading/success/error/recovery 状态齐备。锚:ACC-REV-MINFUNC、F5/F8。
- **源码静默证明**:PackageDelivery MAP 必须含 `## Feature expansion consumption` JSON manifest(product_shape、gap 评估、≥1 area 行:area_id/status/entry_point/state_action_outcome/lifecycle_connection/evidence)。源码侧核对该 manifest 每行的 entry_point 与证据真实存在。
- **评分要点**:manifest 缺失或 simple_thin 无任何 implemented area → block。

### 3. product_maturity:information_architecture_and_navigation · runtime_hard
- **要求(zh)**:IA 由能力图导出。本包须为原生底部 Tab bar(SwiftUI `TabView`),4 个 task-distinct 主 tab:Charts / Create / Stitch / Threads,各自对应一条端到端主任务并保持选中/进行中状态;Settings 与 Credit Shop 从 Charts 导航进入,不得占主 tab;不得用顶部分段控件/浮动按钮替代底部 Tab。锚:build/routes-and-states.md §导航壳。
- **源码静默证明**:根视图存在 `TabView` 且 4 个 tab 项各自绑定独立任务视图;无第 5+ 主 tab;settings/credit_shop 为 push/sheet。
- **Simulator 复现路径**:逐一点 4 个 tab(当前目的地可见高亮)→ tab 间切换后返回原 tab 状态保留 → chart_detail push 前进/返回 → chart_export sheet 关闭 → 杀进程重进恢复现场。截图覆盖每个主 tab 与代表性嵌套路径。

### 4. product_maturity:interaction_and_state_quality · runtime_hard
- **要求(zh)**:每个可见控件都有真实动作与及时反馈;各工作流处理首用/空/有数据/loading/success/disabled/校验/error/中断/重试/取消/恢复态,无静默失败、无重复提交、无意外丢数据、无死路。锚:routes-and-states 各 route 主要状态列;§关键 en-US 反馈文案。
- **源码静默证明**:tab_charts 有 loading/empty/list/error 态;create_wizard 有 denied_camera/denied_photo 分支;chart_export 有 insufficient_credits/denied_photo_write;credit_shop 有 purchasing/success/failed;通用错误文案为友好提示(细节仅记日志),原生错误文本不直接上屏。
- **Simulator 复现路径**:空库空态;购买中→成功/失败态;余额 0 导出 PDF → 引导 credit_shop;删除确认取消与确认两路径;快速重复点击标记格子不丢进度。

### 5. product_maturity:layout_accessibility_and_responsiveness · runtime_hard
- **要求(zh)**:最小 320×568 小屏无溢出/无裁切/无遮挡;格点最小可点 ≥14pt(双指缩放可达 44pt);长内容一律 ScrollView;无硬编码页面高度;Dynamic Type 到 AX3 关键按钮不截断;VoiceOver 格子读出 "row 12, column 34, DMC 310, stitched";色彩不单独承载语义(符号联动)。锚:build/design.md §小屏红线、§可访问性。源码审查 alone 不得 pass。
- **源码静默证明**:无固定高度 Column 式布局;交互元素 ≥44pt;色块必带色号文字。
- **Simulator 复现路径**:小屏模拟器(或最小尺寸)逐主页面截图;放大文字后关键页面截图;编辑器缩放平移操作。

### 6. product_maturity:visual_hierarchy_and_design_polish · runtime_hard
- **要求(zh)**:一套产品专属"织物工作室"设计系统(暖亚麻底 #F5EFE4/#1D1A16、绣线红 #C0453E、靛蓝 #3E5F8A、Aida 格纹肌理、rounded serif 标题),一致应用到每个可达表面:主页、二级页、导航、modal/sheet、空态、loading、校验/错误、交互反馈。任一表面脱离共享系统或像默认模板 → block `visual_system_inconsistency:<surface>`。源码审查 alone 不得 pass。锚:build/design.md §视觉方向。
- **源码静默证明**:全局主题 token 集中定义;核心页面无裸露系统白背景;暗色模式有对应色。
- **Simulator 复现路径**:逐 tab + chart_detail + create_wizard + chart_editor + stitch_session + chart_export + credit_shop + settings 截图,同一轮内核对跨表面一致性与逐表面层级/密度/主行动 placement。

### 7. product_maturity:feature_expressive_ui_ux_and_motion · runtime_hard
- **要求(zh)**:全产品(非仅首页)有目的地动效,三个强制观察点:(a) 表面间导航/转场;(b) 状态变化(loading→content、empty→populated);(c) 主行动确认/反馈。pass 证据必须映射到 build/design.md 的 5 个 moment_id:mot_entry_weave / mot_commit_stitch / mot_success_finish / mot_empty_guide / mot_export_pull,及共享 token(threadEase/pullSpring/weaveStagger/celebrateDuration)。事实上静态的界面或仅首页/启动有动效 → block `motion_floor_not_met:<surface>`;仅首页精修 → `homepage_only_polish`;仅换色/圆角/阴影/模板化 → `template_shell_visual_pass`。Reduce Motion 下用户价值(确认感/进度/完工反馈)以非动画等价保留。编辑器内禁止自动播放动画。锚:ACC-MOT-*;§Motion thesis。
- **源码静默证明**:动效 token 常量存在并被各 moment 引用;每个 moment 有 `accessibilityReduceMotion` 分支;编辑器画布无自动播放动画。
- **Simulator 复现路径**:冷启动首屏织入;标记格子弹簧+进度环;完工描边;空态呼吸;导出抽线/对勾;开启 Reduce Motion 后等价路径逐一截图/录屏。

### 8. product_maturity:workflow_coherence_and_lifecycle · runtime_hard
- **要求(zh)**:能力构成连贯生命周期:创建产出图样 → 编辑/绣制消费它 → 进度是回访资产 → 导出是生命周期出口;术语/归属/状态跨表面一致(draft→active→finished);首用/重复用/重启/回访/数据增长旅程可用;法务/变现工具不遮挡主价值。锚:build/product.md §核心回路 4;F5 状态流转。
- **源码静默证明**:Chart 状态机 draft/active/finished 与进度派生规则一致(build/data-model.md);杀进程重进数据仍在(ACC-004/012);删除级联清理沙盒照片副本。
- **Simulator 复现路径**:首用创建 → 重启 App → 图样与进度仍在 → 回访继续绣 → 完工 → 导出;多图样(数据增长)下列表分组与搜索仍可用。

### 9. ios_delivery:consumable_iap(source-primary)
- **要求(zh)**:真实 StoreKit 消耗型点数链路,唯一允许模型 = yanran 消耗余额目录(`agents/FinalGateAgent/data-contracts/iap/yanran.json`,sha256 b6b737ce…,为唯一权威):product_id `473900`–`473926` 与 amount 逐字保留、ID 仅内部使用不 UI 暴露;校验购买成功后按 amount 入账;**无 Restore Purchases 流程或字样**。消耗触发 = 主表面上的产品专属动作:chart_export 选择 Printable PDF 且导出成功后扣 1 Credit 并生成 ExportRecord(含 storekitTransactionId);不得为打开 paywall/浏览/取消/失败交易扣点。余额 0 时引导 credit_shop;settings 余额行可进 credit_shop。首启赠送与档位展示以目录 initial_balance/products 为准,PM 文案("grant 2 枚""5/15/40 档")若与目录数值冲突,以目录为准、由 PDA 对齐,不得自造第二套商品。锚:build/ai-and-privacy.md §Commerce card;F10/F11;ACC-009/010;ACC-REV-IAP。
- **源码静默证明**:StoreKit2 购买/校验/入账代码;目录 product_id 常量逐字匹配 yanran.json;全仓 grep 无 "Restore" 字样与 restore 调用;扣减仅在 PDF 生成成功后;ExportRecord 持久化含 transactionId。
- **评分要点**:PM 消耗制与政策一致,无 `checklist_policy_iap_model_conflict`。

### 10. ios_delivery:legal_webviews(source-primary)
- **要求(zh)**:应用内两个独立 WebView 入口——隐私政策与用户协议,各自独立 HTTPS 模板 URL,从 settings(或 onboarding)可达,含加载失败处理。锚:ACC-011、build/ai-and-privacy.md §隐私说明入口。
- **源码静默证明**:两个不同 URL 常量(HTTPS);settings 有对应入口行;WebView 有错误/重试态。

### 11. ios_delivery:functional_images · runtime_hard
- **要求(zh)**:≥4 个不同可达页面/工作区有视觉媒体能力,其中 ≥3 个页面主功能图占可用视口 30–70%(参考 iPhone 布局,不含系统 chrome 与常驻导航)。计入的图必须是绑定域记录/用户动作/持久化结果的运行时产品媒体:**bundle 内美术资产不计入**阈值。本包映射:① create_wizard 源照片预览(用户媒体,占预览屏 40–60%);② chart_detail 格点渲染大图(运行时渲染,30–50%);③ stitch_session 格点画布 + 当前色高亮;④ chart_export 图卡预览(格点渲染+成品照);⑤ tab_charts 卡片格点缩略图。每页任务/生命周期上下文 materially different,且绑定具体操作与可观测结果。纯 SF Symbol 壳不计。锚:build/design.md §In-app image slots;ACC-VIS-MEDIA。
- **源码静默证明**:各 slot 在对应 route 有真实 SwiftUI 视图(Image(uiImage:)/PhotosPicker/Canvas 渲染);empty_fallback 路径存在。
- **Simulator 复现路径**:含用户照片与格点渲染数据走一遍,逐页截图并标注视口占比;验证缩略图为真实格点渲染而非源照片或 SF Symbol。

### 12. ios_delivery:camera_permission · runtime_hard
- **要求(zh)**:真实 JIT 相机权限路径,record-bound(建图拍照、完工成品照)。`NSCameraUsageDescription` 用产品专属文案(PM 给定:"Take a photo to turn into a stitch chart, or snap your finished piece. Photos stay on this device."),不得用模板文案。仅在显式拍摄动作后请求;取消保留在制工作;拒绝/受限给产品专属恢复文案(命名被中断的拍摄任务)+ 应用内继续入口(Choose Photo / 跳过成品照);**永不跳 Settings、无 openSettingsURLString**。Simulator 无相机硬件:产品必须暴露确定性捕获替代 seam(如 UI-test 注入 capture provider),用合成媒体证明 权限→捕获→媒体绑定到 Chart 全旅程;仅走"相机不可用"恢复分支不得 pass。锚:ACC-003/006;F7/F12。
- **源码静默证明**:Info.plist 键存在且文案产品化;`AVCaptureDevice.requestAccess` 调用点在拍摄动作处理器;拒绝分支无 Settings 跳转;存在 capture provider 抽象/注入点。
- **Simulator 复现路径**:触发拍摄动作 → 权限弹窗(或 seam 合成授权)→ 合成照片绑定到新 Chart/成品照 → 拒绝路径显示 Choose Photo/可跳过且不阻塞完工。截图 + readback。

### 13. ios_delivery:photo_library_read_write_permission · runtime_hard
- **要求(zh)**:真实相册**读**(导入照片建图样)与**写**(导出图卡存相册)双能力。`NSPhotoLibraryUsageDescription` 与 `NSPhotoLibraryAddUsageDescription` 均为产品专属文案(PM 已给两条);JIT 请求;处理首用/ granted / limited / denied / restricted / retry / 取消 / 保留现场;拒绝文案命名被中断的导入或保存动作 + 应用内继续(Start Blank / Share / Retry);永不跳 Settings。CTA 可见 + 源码 JIT 不足以 pass:Simulator 完整支持读写,运行时证据必须各跑一次真实 granted 导入与真实 granted 保存并绑定域记录。锚:ACC-002/008;F2/F9/F12。
- **源码静默证明**:两个 plist 键;PhotosPicker/PHPhotoLibrary 写路径;denied_photo_write 分支有 Share 替代。
- **Simulator 复现路径**:相册选图 → 生成图样(读);导出图卡 → 保存到相册成功(readback 确认 asset 存在);拒绝写 → Share/Retry,无 Settings。

### 14. ios_delivery:microphone_permission_boundary · runtime_hard(缺席分支)
- **适用分支**:**缺席分支**。PM 声明不使用麦克风(build/ai-and-privacy.md),能力图(F1–F12)无任何音频相关工作流(无语音笔记/听写/音频标注),缺席声明为真,非冲突。
- **要求(zh)**:缺席仅在独立证明集齐备时 pass:① 所有 Info.plist 无 `NSMicrophoneUsageDescription`;② 源码无音频录制 API 引用(`AVAudioRecorder`/`AVAudioApplication`/`AVAudioSession` 录制类用法);③ 有聚焦缺席测试;④ Simulator 全主流程扫描零意外麦克风弹窗。
- **源码静默证明**:grep 结果 + 缺席测试文件。
- **Simulator 复现路径**:主流程全走一遍,日志无麦克风权限请求。

### 15. ios_delivery:app_tracking_transparency · runtime_hard(缺席分支)
- **适用分支**:**缺席分支**。PM 声明零第三方分析 SDK、无跟踪无广告(build/ai-and-privacy.md §Privacy),无兼容的可选跟踪目的,缺席声明为真。
- **要求(zh)**:缺席证明集:① 无 `NSUserTrackingUsageDescription`;② 无 `ATTrackingManager`/`AdSupport`/IDFA 引用;③ `PrivacyInfo.xcprivacy` 声明 `NSPrivacyTracking=false`(且仅声明实际必要项);④ 聚焦缺席测试;⑤ Simulator 全主流程零意外跟踪弹窗。
- **源码静默证明**:grep + PrivacyInfo 文件内容 + 缺席测试。
- **Simulator 复现路径**:主流程全走,无 ATT 弹窗。

### 16. ios_delivery:keyboard_dismissal(source-primary)
- **要求(zh)**:每个文本输入面(如图样命名、搜索框)提供明确键盘收起交互(tap-away/return/工具栏完成),且不丢失已输入内容。
- **源码静默证明**:所有 TextField 所在视图有失焦收起实现(scrollDismissesKeyboard/onSubmit/toolbar Done 等);输入态绑定不随收起清空。

### 17. product_maturity:functional_completeness_final_review(必须最后评)
- **要求(zh)**:对每条声明能力与每条可达功能链做最终完整性复审:入口、状态迁移、用户动作、可观测结果、持久化/生命周期、跨功能接力、失败路径、恢复路径、用户可见完成。未实现控件、占位、死路、断链、半截状态处理、静默失败、不持久、只有 happy path 均不得 pass。"产品完整"的空话不是证据。锚:ACC-REV-COMPLETE;F1–F12 全表。
- **源码静默证明**:PackageDelivery MAP 必须含 `## Functional completeness final review` JSON manifest,逐 capability/chain area 一行(area_id/status/entry_point/state_action_outcome/chain_connection/evidence);QA 抽查每行证据真实。任何 area 未审/无证据/blocked → ready 无效。
- **评分要点**:本条排最后;依赖前 16 条结论 + manifest 逐项核对。

---

## B. PM 图像 slot 检查(必备,独立于政策集)

### 18. pm_image_slot:app_icon
- 要求:App Icon asset 存在且被 Assets/Info 引用,非默认空白图标(针穿格点品牌图标)。锚:ACC-VIS-ICON。证明:asset catalog imageset 非空 + 构建产物引用。

### 19. pm_image_slot:charts_hero
- 要求:tab_charts 首屏 hero(针线穿格点主题插画区,约占首屏 30–40%),空/有数据均有品牌视觉;fallback = 亚麻底 + `rectangle.grid.3x3`。锚:ACC-VIS-HERO。证明:首屏源码存在 hero 视图 + Simulator 空/有数据两态截图。

### 20. pm_image_slot:charts_empty_illustration
- 要求:空库插画(空绣绷)可见,含 fallback(SF Symbol `photo.on.rectangle` + 主色圆底)。锚:ACC-VIS-EMPTY。证明:空态源码 + Simulator 空库截图。

### 21. pm_image_slot:photo_or_media
- 要求:create_source_photo / chart_thumbnail / finished_piece_photo 三 slot 走真实用户媒体与运行时格点渲染路径;有用户照片时显示真实照片;缩略图为格点渲染非 SF Symbol。锚:ACC-VIS-MEDIA。证明:源码三 slot 视图 + Simulator 带数据截图(与 check 11 证据可复用)。

---

## C. PM 其他派生检查

### 22. pm_ai:no_remote_ai_boundary
- **要求(zh)**:PM 声明 remote_ai: no。源码不得出现远程 AI/relay 客户端、trial gate、明文 endpoint/key/model;F2 照片转格点为端上确定性色彩量化(中位切分或等价),无网络请求。不强制 factory trial=1。锚:build/ai-and-privacy.md §AI implementation card。
- **源码静默证明**:grep 无 URLSession/relay/AI endpoint 调用;量化算法文件存在且纯本地。

### 23. pm_acc:permission_denied_no_settings
- **要求(zh)**:三条权限拒绝路径(相机/相册读/相册写)全部应用内继续,文案与 PM copy intent 一致;全仓无 `Open Settings` 文案与 `openSettingsURLString` 调用。锚:ACC-003/008;routes-and-states §状态红线;F12。
- **源码静默证明**:grep `openSettingsURLString|UIApplication.openSettingsURLString` 为零;拒绝分支按钮为 Choose Photo/Start Blank/Share/Retry。

### 24. pm_acc:review_diff_dedupe(信息性)
- **要求(zh)**:4.3 无 check_id——当本包 dedupe 记录(creation_tool/cross-stitch-craft,与近期包 TourWise/ReadyAt 不同骨架不同领域)显示 distinct fingerprint 即视为满足;QA 仅引用 dedupe 记录,不新增评分项。锚:ACC-REV-DIFF。

### 25. pm_build:headless_build(可选)
- **要求(zh)**:Xcode 可用时工程应能 headless 构建(`xcodebuild`,外部 DerivedData);作为 build 类证据支持上述检查,不单独阻断。
- **证明**:构建日志(成功)路径。

---

## 备注

- 运行时证据统一由 verification 阶段经 `ios_runtime_acceptance` 采集,hash-bound 落盘;本清单不授权在 checklist 阶段运行任何构建/模拟器。
- AI 无远程 → 凭证密封(credential package)检查**跳过**(PM 已记录 no remote AI)。
- 全部产品 UI 文案保持 en-US;本清单仅为中文操作者文档。
