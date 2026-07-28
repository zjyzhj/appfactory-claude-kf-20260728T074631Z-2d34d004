# ThreadGrid · full_rewrite MAP (attempt-1)

**Status: ready**

- Product repo: `/Volumes/zjySD/claude-app-factory/runs/kf-20260728T074631Z-2d34d004/product`(branch main, commit `30757b5` rough_app attempt-1,worktree clean,local == origin)
- Contract: `/Volumes/zjySD/claude-app-factory/runs/kf-20260728T074631Z-2d34d004/stages/checklist/attempt-1/MAP.md`
- Checks file: `/Volumes/zjySD/claude-app-factory/runs/kf-20260728T074631Z-2d34d004/stages/checklist/attempt-1/checks.md`(25 条,全量消费,零新增标准)
- IAP 权威:`agents/FinalGateAgent/data-contracts/iap/yanran.json`(grant=100,product_id 473900–473926 逐字,amount/price/promotion 脚本比对 ZERO mismatch)

## What changed

本轮为**纯审计轮**:F2 批量静默审计(grep + plist + yanran.json 脚本逐字比对)覆盖全部 25 条 check_id 的源码静默证明点,rough_app attempt-1 交付物全部命中,未发现需要实现的真实 gap,因此 **repo 零改动、零新提交**(playbook 允许:全行 already_ok 时空产品工作是合法结果)。runtime_hard 条目的 Simulator 证据由 verification 阶段经 `ios_runtime_acceptance` 采集;本阶段只完成源码层确认与两个必需 manifest 的回写。

审计覆盖点(抽样):4-tab `TabView` 绑定独立任务视图;F2 量化纯端上(`Imaging/ChartQuantizer.swift`);全仓零 `URLSession`/网络调用、零 `TODO`/placeholder、零 `openSettingsURLString`、零 Restore 字样;相机/相册读/写三键为 PM 产品文案且 JIT;麦克风/ATT 缺席证明(`AbsenceTests.swift` 4 测试 + plist 无键 + `PrivacyInfo.xcprivacy` `NSPrivacyTracking=false`);`accessibilityReduceMotion` 分支在 6 个视图;格子 a11y label 含 "row N, column N, DMC code, state";PDF 扣点严格在渲染成功之后(`ChartExportView.exportPDF`,注释直引 checklist §9);删除级联清理沙盒照片;两个独立 HTTPS legal URL + sheet WebView;shop UI 从逐字目录策展展示(9 standard + 4 promotion,`CreditCatalog.displayedProducts`),与主控对齐决策一致。

## Checks

| # | check_id | status | evidence / note |
|---|----------|--------|-----------------|
| 1 | product_maturity:core_value_and_feature_completeness | already_ok | 4 tab 根视图 + F1–F12 真实实现;`ChartQuantizer` 端上量化;编辑器 undo 栈、完工检测、权限拒绝替代入口均在;全仓 grep 零 TODO/placeholder;创建→编辑→绣制→导出闭环走通(UI E2E `testCreateChartThroughCameraSeam` 49.3s pass) |
| 2 | product_maturity:feature_expansion | already_ok | product_shape=already_mature;manifest 见下 `## Feature expansion consumption` |
| 3 | product_maturity:information_architecture_and_navigation | already_ok | `ThreadGridApp.swift:26` 原生 `TabView` 4 tab(Charts/Create/Stitch/Threads);settings 为 push、credit_shop 为 sheet;无第 5 主 tab、无顶部段控替代 |
| 4 | product_maturity:interaction_and_state_quality | already_ok | 空/有数据/loading/error 各态齐备:export 有 insufficientCredits/deniedPhotoWrite/failed;shop 有 purchasing/success/failed;create 有 deniedCamera/deniedPhotoRead;拒绝态均为应用内继续(Share/Retry/Choose Photo),错误文案友好、细节仅日志 |
| 5 | product_maturity:layout_accessibility_and_responsiveness | already_ok | 长内容 ScrollView;固定高度仅 9 处均为有界组件(hero 210/预览 240–280/hairline 1),无固定高度页面 Column;交互元素 minHeight 44;格子 a11y label 格式 "row 12, column 34, DMC 310, stitched"(`GridCanvasView.swift:474`);色块带色号文字 |
| 6 | product_maturity:visual_hierarchy_and_design_polish | already_ok | `App/Theme.swift` 集中 token(暖亚麻 #F5EFE4/绣线红 #C0453E/靛蓝 #3E5F8A + 暗色对应);Aida 格纹肌理、serif 标题;核心表面无裸系统白 |
| 7 | product_maturity:feature_expressive_ui_ux_and_motion | already_ok | `MotionLanguage.swift` 共享 token;5 moment_id 全部落位(mot_entry_weave/mot_commit_stitch/mot_success_finish/mot_empty_guide/mot_export_pull);每个 moment 有 Reduce Motion 等价;编辑器画布零自动播放 |
| 8 | product_maturity:workflow_coherence_and_lifecycle | already_ok | draft→active→finished 状态机一致;`AppStore`+`LocalStore` 持久化,杀进程重进恢复;删除级联清理 source/finished 沙盒照片(`AppStore.swift:141-143`) |
| 9 | ios_delivery:consumable_iap | already_ok | StoreKit2 购买/校验/入账(`CreditShopManager`);27 个 product_id + amount/price/promotion 与 yanran.json 脚本比对 ZERO mismatch;initial_balance=100;扣点仅在 PDF 渲染成功后(`ChartExportView.swift:248`,注释直引 §9);ExportRecord 含 `storekitTransactionId`;余额 0 引导 credit_shop;settings 余额行进店;全仓零 Restore 字样 |
| 10 | ios_delivery:legal_webviews | already_ok | 两个独立 HTTPS URL(`SettingsView.swift:91-92` privacy/terms);settings 入口行;sheet WebView 含失败重试态 |
| 11 | ios_delivery:functional_images | already_ok | 5 处运行时/用户媒体:create 源照片预览 `Image(uiImage:)`、chart_detail 格点渲染大图(`ChartRenderer .detail`)、stitch_session 格点画布+当前色高亮、export 图卡预览(含 DMC key+成品照)、tab_charts 格点缩略图(`ChartCardView` `.thumbnail`,非源照片非 SF Symbol) |
| 12 | ios_delivery:camera_permission | already_ok | plist 相机键为 PM 逐字文案;`AVCaptureDevice.requestAccess` 在拍摄动作处理器内 JIT;`-syntheticCapture` 确定性 seam(`CaptureSupport.swift:25-41`);拒绝分支应用内继续,零 Settings 跳转 |
| 13 | ios_delivery:photo_library_read_write_permission | already_ok | 读/写双 plist 键均为 PM 产品文案;PhotosPicker 读 + PHPhotoLibrary 写;denied_photo_write 分支给 Share/Retry 替代;无 Settings 跳转 |
| 14 | ios_delivery:microphone_permission_boundary | already_ok | 缺席分支:pbxproj INFOPLIST_KEY 无麦克风键;全仓零 AVAudioRecorder/AVAudioApplication/AVAudioSession 录制用法;`AbsenceTests.swift` 聚焦缺席测试在 |
| 15 | ios_delivery:app_tracking_transparency | already_ok | 缺席分支:无 NSUserTrackingUsageDescription;零 ATTrackingManager/AdSupport/IDFA;`PrivacyInfo.xcprivacy` NSPrivacyTracking=false(仅声明 UserDefaults CA92.1 + FileTimestamp C617.1);缺席测试在 |
| 16 | ios_delivery:keyboard_dismissal | already_ok | 全部 TextField 视图有 `scrollDismissesKeyboard(.interactively/.immediately)` 或 `onSubmit`;输入绑定不随收起清空 |
| 17 | product_maturity:functional_completeness_final_review | already_ok | manifest 见下 `## Functional completeness final review`(14 个 area 逐行审,全部 implemented) |
| 18 | pm_image_slot:app_icon | already_ok | `AppIcon.appiconset/AppIcon.png`(1024×1024,pm_visuals 品牌栅格,非默认空白) |
| 19 | pm_image_slot:charts_hero | already_ok | `charts_hero.imageset` + `ChartsHomeView.swift:197` hero Image,空/有数据两态均在;fallback 路径保留 |
| 20 | pm_image_slot:charts_empty_illustration | already_ok | `charts_empty_illustration.imageset` + 空态 Image(`ChartsHomeView.swift:313-314`),SF Symbol fallback 保留 |
| 21 | pm_image_slot:photo_or_media | already_ok | 三 slot 全真:create_source_photo(`CreateWizardView.swift:235`)/chart_thumbnail(ChartRenderer 运行时渲染)/finished_piece_photo(FinishedPhotoSheet → chart_detail 成品照区块) |
| 22 | pm_ai:no_remote_ai_boundary | already_ok | 全仓零 URLSession/relay/endpoint/key;`ChartQuantizer` median-cut 纯端上确定性;唯一 https 引用为两个 legal URL 常量 |
| 23 | pm_acc:permission_denied_no_settings | already_ok | grep `openSettingsURLString` 零命中;三条拒绝路径按钮均为 Choose Photo/Start Blank/Share/Retry |
| 24 | pm_acc:review_diff_dedupe | already_ok | 信息性:creation_tool/cross-stitch-craft 骨架,与 TourWise/ReadyAt 不同领域,distinct fingerprint 成立,QA 引用 dedupe 记录即可 |
| 25 | pm_build:headless_build | already_ok | `stages/rough_app/attempt-1/logs/build-5.log` xcodebuild BUILD SUCCEEDED(外部 DerivedData);`test-final.log` 18/18 TEST SUCCEEDED;本阶段零源码改动,沿用该证据,不重跑构建剧场 |

## Feature expansion consumption

```json
{
  "check_id": "product_maturity:feature_expansion",
  "product_shape": "already_mature",
  "gap_assessment": "ThreadGrid 声明 F1–F12(图样库/三源创建/编辑器/绣制会话/线库/导出/消耗制 IAP),核心任务生命周期完整:创建产出图样→编辑/绣制消费→进度为回访资产(持久化+进度环)→导出为生命周期出口;empty/loading/success/error/recovery 态齐备;有回访价值(图样库+进度资产+线量清单)。非 simple_thin,不触发强制 domain 扩展;无 theme-color/notification-toggle 填充物。",
  "areas": [
    {
      "area_id": "stitch_progress_asset",
      "status": "already_ok",
      "entry_point": "tab_stitch → StitchSessionView(符号过滤+当前色高亮+标记确认)",
      "state_action_outcome": "active 态图样逐格标记→进度环实时更新→最后一格触发完工检测(mot_success_finish)→status 流转 finished",
      "lifecycle_connection": "进度持久化(LocalStore),杀进程重进恢复;完工图样进入 finished 分组并可捕获成品照",
      "evidence": "ThreadGrid/Views/Stitch/StitchSessionView.swift:247(完工检测);ThreadGrid/App/AppStore.swift(进度持久化)"
    },
    {
      "area_id": "threads_stash_lifecycle",
      "status": "already_ok",
      "entry_point": "tab_threads → ThreadsView(DMC 色库+我的 stash+图样线量清单)",
      "state_action_outcome": "浏览/搜索 DMC 色库→管理 stash→按图样查看线量需求→回访备线决策",
      "lifecycle_connection": "stash 持久化;线量清单从图样 palette 派生,连接创建产出与绣制消费",
      "evidence": "ThreadGrid/Views/Threads/ThreadsView.swift;ThreadGrid/Models/DMCThread.swift"
    },
    {
      "area_id": "export_lifecycle_exit",
      "status": "already_ok",
      "entry_point": "chart_detail → chart_export sheet(免费图卡/1-Credit Printable PDF)",
      "state_action_outcome": "图卡存相册/分享(免费);PDF 渲染成功后才扣 1 Credit 并落 ExportRecord(含 storekitTransactionId);余额 0 引导 credit_shop",
      "lifecycle_connection": "导出为图样生命周期出口;ExportRecord 持久化构成回访记录;消耗制 IAP 闭环",
      "evidence": "ThreadGrid/Views/Export/ChartExportView.swift:237-258;ThreadGrid/Export/ExportEngine.swift;ThreadGrid/Models/Credits.swift:34"
    }
  ]
}
```

## Functional completeness final review

```json
{
  "check_id": "product_maturity:functional_completeness_final_review",
  "reviewed_after": "checks 1-16 + 18-25 全部 already_ok 后最后评审",
  "areas": [
    {"area_id": "chart_library", "status": "implemented", "entry_point": "tab_charts → ChartsHomeView", "state_action_outcome": "empty(插画+CTA)/list(格点缩略图+进度环+搜索+状态分组)/loading;点图卡→chart_detail", "chain_connection": "出口到 create_wizard/chart_detail/settings", "evidence": "ThreadGrid/Views/Charts/ChartsHomeView.swift;UI E2E testTabSwitchingRendersEveryRoot pass"},
    {"area_id": "create_from_photo", "status": "implemented", "entry_point": "tab_create → create_wizard → PhotosPicker", "state_action_outcome": "相册选图→源照片预览(40-60%)→调尺寸/色数→端上量化→预览→命名保存", "chain_connection": "保存后入库→chart_detail;denied_photo_read 分支 Start Blank 继续", "evidence": "ThreadGrid/Views/Create/CreateWizardView.swift;ThreadGrid/Imaging/ChartQuantizer.swift"},
    {"area_id": "create_from_camera", "status": "implemented", "entry_point": "create_wizard → Take Photo", "state_action_outcome": "JIT 权限→捕获(或 -syntheticCapture seam)→同一量化管线;取消保留在制工作;拒绝给 Choose Photo 恢复", "chain_connection": "与照片源汇合到量化→预览→保存", "evidence": "ThreadGrid/Capture/CaptureSupport.swift:25-41;UI E2E testCreateChartThroughCameraSeam 49.3s pass"},
    {"area_id": "create_blank", "status": "implemented", "entry_point": "create_wizard → Start Blank", "state_action_outcome": "空白格点→编辑器直接绘制", "chain_connection": "进入 chart_editor 作为主创作面", "evidence": "ThreadGrid/Views/Create/CreateWizardView.swift(denied 恢复分支同入口)"},
    {"area_id": "chart_editor", "status": "implemented", "entry_point": "chart_detail → Edit → chart_editor", "state_action_outcome": "画笔/橡皮/整色替换/undo 栈;pinch 缩放;格点≥14pt;画布零自动播放动画", "chain_connection": "编辑结果持久化回图样;绣制会话消费同一数据", "evidence": "ThreadGrid/Views/Editor/ChartEditorView.swift"},
    {"area_id": "stitch_session", "status": "implemented", "entry_point": "tab_stitch / chart_detail → Start stitching", "state_action_outcome": "符号过滤+当前色高亮→标记格子(haptic+进度环)→完工描边庆祝→成品照捕获(可跳过)", "chain_connection": "进度为回访资产;完工流转 finished;成品照进 chart_detail 与导出图卡", "evidence": "ThreadGrid/Views/Stitch/StitchSessionView.swift:247-265;FinishedPhotoSheet.swift"},
    {"area_id": "threads_stash", "status": "implemented", "entry_point": "tab_threads", "state_action_outcome": "DMC 色库搜索/stash 管理/图样线量清单", "chain_connection": "线量从图样 palette 派生,服务绣制备线", "evidence": "ThreadGrid/Views/Threads/ThreadsView.swift"},
    {"area_id": "export_image_card", "status": "implemented", "entry_point": "chart_export → Save Card / Share", "state_action_outcome": "格点渲染图卡(含 DMC key+成品照)→存相册(JIT 写权限)/系统分享;denied_photo_write→Share/Retry", "chain_connection": "免费生命周期出口;recordExport 落账", "evidence": "ThreadGrid/Export/ExportEngine.swift(makeResultCard);ChartExportView.swift:200-230"},
    {"area_id": "export_printable_pdf", "status": "implemented", "entry_point": "chart_export → Printable PDF(1 Credit)", "state_action_outcome": "余额校验→渲染→成功后才扣 1 Credit+ExportRecord(transactionId)→分享 PDF;余额 0→Get Credits 进店", "chain_connection": "消耗制变现闭环;ExportRecord 持久化", "evidence": "ThreadGrid/Views/Export/ChartExportView.swift:237-258;Credits.swift:34"},
    {"area_id": "credit_shop", "status": "implemented", "entry_point": "settings 余额行 / 余额 0 引导 → credit_shop sheet", "state_action_outcome": "目录逐字 27 档(展示 9 standard+4 promotion)→StoreKit2 购买(purchasing/success/failed)→按 amount 入账;productsLoadFailed 重试态;无 Restore", "chain_connection": "入账余额反哺 PDF 导出消耗", "evidence": "ThreadGrid/Store/CreditShopManager.swift;Views/Shop/CreditShopView.swift;yanran.json 逐字比对 ZERO mismatch"},
    {"area_id": "settings_legal", "status": "implemented", "entry_point": "tab_charts 导航 push → settings", "state_action_outcome": "余额行进店;两个独立 HTTPS legal WebView(失败重试态);隐私说明;about", "chain_connection": "法务/变现不遮挡主价值(push+sheet,不占主 tab)", "evidence": "ThreadGrid/Views/Settings/SettingsView.swift:82-92"},
    {"area_id": "permissions_recovery", "status": "implemented", "entry_point": "相机/相册读/相册写三 JIT 点", "state_action_outcome": "granted/limited/denied/restricted/retry/取消全覆盖;拒绝命名被中断动作+应用内继续;零 openSettingsURLString", "chain_connection": "拒绝不阻塞主流程(Choose Photo/Start Blank/Share/Retry)", "evidence": "grep openSettingsURLString 零命中;CaptureSupport.swift;ChartExportView deniedPhotoWrite 分支"},
    {"area_id": "persistence_lifecycle", "status": "implemented", "entry_point": "AppStore+LocalStore(全链路)", "state_action_outcome": "图样/进度/stash/ledger/ExportRecord 持久化;杀进程重进恢复现场(tab 选中态保留);删除级联清理沙盒照片", "chain_connection": "横切所有 area 的生命周期底座", "evidence": "ThreadGrid/App/AppStore.swift:137-143;Persistence/LocalStore.swift;PersistenceAndRenderTests 4 测试 pass"},
    {"area_id": "motion_accessibility", "status": "implemented", "entry_point": "全产品 5 moment_id", "state_action_outcome": "entry weave/commit stitch/success finish/empty guide/export pull 全落位;每 moment 有 Reduce Motion 等价;格子 VoiceOver label 含行列+DMC+状态", "chain_connection": "确认感/进度/完工反馈在 Reduce Motion 下以非动画等价保留", "evidence": "ThreadGrid/App/MotionLanguage.swift;GridCanvasView.swift:474;6 视图 accessibilityReduceMotion 分支"}
  ]
}
```

## Gaps

无阻塞缺口。两条信息性记录(沿用 rough MAP 对齐决策,主控已确认):

1. **IAP 数值以 yanran.json 为唯一权威**:首启 grant=100、27 档逐字(amount/price/promotion 脚本比对 ZERO mismatch);PM 文案"grant 2 枚 / 5·15·40 档"未采用;shop UI 从逐字目录策展展示(9 standard + 4 promotion,`CreditCatalog.displayedProducts`),与主控提醒的"档位展示可对齐目录"一致,无需再改。
2. Smoke 截图图样名 "Photo chartSmoke Fox" 为 UI 测试键入拼接产物,命名输入框用户可改,非产品文案缺陷。

runtime_hard 条目(checks 1/3/4/5/6/7/8/11/12/13/14/15)的 Simulator 证据采集属 verification 阶段(`ios_runtime_acceptance`,hash-bound),本阶段不代跑;源码静默证明点已全部命中(见 Checks 表)。
