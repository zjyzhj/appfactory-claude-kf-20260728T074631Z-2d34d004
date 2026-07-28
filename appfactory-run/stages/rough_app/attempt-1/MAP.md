# ThreadGrid · rough_app MAP

**Status: ready**

一句话:ThreadGrid 是本地优先、零账号的 iPhone 十字绣图样工作室——导入照片生成可编辑的 DMC 线色格点图,逐格标记绣制进度,导出可打印图解存档。remote_ai: no;yanran 消耗制 Export Credits。

## Project identity

- app_name: ThreadGrid
- project_name: ThreadGrid
- xcodeproj_name: ThreadGrid.xcodeproj
- scheme_name: ThreadGrid
- target_name: ThreadGrid

## Repo & upstream

- Product repo: `runs/kf-20260728T074631Z-2d34d004/product/` — commit `30757b5` on `main`, **pushed** to `origin` (github.com/zjyzhj/appfactory-claude-kf-20260728T074631Z-2d34d004), worktree clean, local == remote.
- Upstream read: PM MAP + `build/*` 全部章节(product / routes-and-states / data-model / features / ai-and-privacy / design / acceptance / non-goals);checklist MAP + `checks.md`(25 条,open-book);pm_visuals MAP + 6 frames + 3 slot rasters。未读 `research/*`(按规跳过)。

## What shipped(S0–S7;S3 skipped — remote_ai: no)

- **IA(routes-and-states 全量 10 route)**:原生底部 `TabView` 4 tab —— Charts / Create / Stitch / Threads;`settings` 为 Charts 导航 push,`credit_shop` 为 sheet;chart_detail / chart_editor push,chart_export sheet。选中态保留、杀进程重进恢复现场(AppStore + LocalStore 持久化)。
- **F1–F12 真实实现**:图样库(真实格点渲染缩略图 + 进度环 + 搜索/状态分组);创建向导(camera / PhotosPicker / blank 三源 → 端上 median-cut DMC 量化,确定性、零网络);格点编辑器(画笔/橡皮/整色替换/undo 栈,pinch 缩放,格点 ≥14pt);绣制会话(符号过滤、当前色高亮、标记确认、完工描边庆祝 + 成品照捕获);Threads tab(DMC 色库 + 我的 stash + 图样线量清单);导出(免费图卡存相册/分享,Printable PDF 扣 1 Credit)。
- **IAP(yanran 唯一权威目录)**:27 个 product_id `473900`–`473926` 逐字保留(amount/price/promotion 与 `yanran.json` 一致),首启赠送 100(initial_balance),StoreKit2 + `ThreadGrid.storekit`;PDF 生成成功后才扣 1 Credit 并落 `ExportRecord`(含 storekitTransactionId);余额 0 引导 credit_shop;settings 余额行可进店;**无 Restore 流程与字样**(全仓 grep 仅 CoreGraphics `restoreGState`)。
- **权限与合规**:相机 + 相册读/写三键均为 PM 产品文案,JIT(record-bound);拒绝/受限全部应用内继续(Choose Photo / Start Blank / Share / Retry),**零 `openSettingsURLString`**;Simulator 确定性捕获 seam `-syntheticCapture`(CaptureSupport.swift);麦克风/ATT 缺席分支(无键、无 API、聚焦缺席测试);`PrivacyInfo.xcprivacy` `NSPrivacyTracking=false`;settings 内两个独立 HTTPS legal WebView(privacy / terms,含失败重试态);全 UI en-US;无 URLSession/任何网络调用。
- **视觉系统**:暖亚麻 `#F5EFE4` / 绣线红 `#C0453E` 主色(暖色政策合规),靛蓝/鼠尾草仅作数据与状态 accent;Theme.swift 集中 token、Aida 格纹肌理、serif 标题,暗色模式适配,核心表面无裸系统白。
- **Motion**:MotionLanguage 集中 token(threadEase 0.35s easeOut / pullSpring spring(0.4, 0.7) / weaveStagger 0.03s / celebrateDuration 1.2s);5 个 moment 全部落位——mot_entry_weave(tab_charts 首帧织入)、mot_commit_stitch(标记 pullSpring + .light haptic + 进度环)、mot_success_finish(完工描边 1.2s + .success haptic)、mot_empty_guide(空态 2.5s 呼吸)、mot_export_pull(导出抽线 + 对勾,.medium haptic);每个 moment 有 Reduce Motion 等价分支;编辑器画布零自动播放动画。

## Image slots(design.md §In-app image slots,6/6)

| slot_id | 实现 |
|---------|------|
| app_icon | `Assets.xcassets/AppIcon.appiconset`(pm_visuals slot 栅格 1254→1024 重采样) |
| charts_hero | `Assets.xcassets/charts_hero.imageset` + `ChartsHomeView` hero `Image`(空/有数据两态均在,约占首屏 1/3) |
| charts_empty_illustration | `Assets.xcassets/charts_empty_illustration.imageset` + 空态 `Image`(SF Symbol fallback 路径保留) |
| create_source_photo | `CreateWizardView` 源照片预览(`Image(uiImage:)` / PhotosPicker,预览屏 40–60%,转图前后对比) |
| chart_thumbnail | `ChartRenderer` 运行时格点渲染(图卡 76pt + 详情大图;非源照片、非 SF Symbol) |
| finished_piece_photo | `FinishedPhotoSheet` 相机/相册捕获 → chart_detail 成品照区块(无照片不渲染,符合契约) |

## Upstream visuals

- pm_visuals status: **ready**(6/6 frames + 3/3 slot rasters 全部读取并使用)
- frames_read:

  | frame_id | path | used_for |
  |----------|------|----------|
  | frame_charts_home | stages/pm_visuals/attempt-1/frames/frame_charts_home.png | tab_charts 布局/密度:hero 区、状态 chips、图卡(格点缩略图 + 进度环) |
  | frame_charts_empty | stages/pm_visuals/attempt-1/frames/frame_charts_empty.png | 空态层级:插画 + 大标题 + 主红 CTA + 次级入口 |
  | frame_create_preview | stages/pm_visuals/attempt-1/frames/frame_create_preview.png | create_wizard 预览:源图→格点对比、尺寸/色数滑杆、Symbols/Color/Both 切换 |
  | frame_chart_editor | stages/pm_visuals/attempt-1/frames/frame_chart_editor.png | 编辑器:全幅符号格点、R·C 指示、DMC 色条、undo chrome |
  | frame_stitch_session | stages/pm_visuals/attempt-1/frames/frame_stitch_session.png | 绣制:进度环 + 半渲染画布(未绣符号态)+ DMC 剩余量色条 + Mark CTA |
  | frame_chart_export | stages/pm_visuals/attempt-1/frames/frame_chart_export.png | 导出:图卡预览(含 DMC key)、免费图卡 / 1-credit PDF 行、余额行、Export CTA |

- frames_ignored: none。**注意**:frames 底栏 chrome(Stash/Settings 等)为参考意象;IA 以 build 文本为准(4-tab Charts/Create/Stitch/Threads,settings push)——truth priority: build text > frames,已在构建时按文本执行。
- slot_assets_used:

  | slot_id | path | imageset_or_view |
  |---------|------|------------------|
  | app_icon | stages/pm_visuals/attempt-1/slots/app_icon.png | `Assets.xcassets/AppIcon.appiconset/AppIcon.png`(1024×1024) |
  | charts_hero | stages/pm_visuals/attempt-1/slots/charts_hero.png | `Assets.xcassets/charts_hero.imageset` → `Image("charts_hero")` @ ChartsHomeView |
  | charts_empty_illustration | stages/pm_visuals/attempt-1/slots/charts_empty_illustration.png | `Assets.xcassets/charts_empty_illustration.imageset` → `Image("charts_empty_illustration")` @ ChartsHomeView 空态 |

- slot_assets_ignored: none(create_source_photo / chart_thumbnail / finished_piece_photo 按契约为用户媒体/运行时渲染,无打包栅格)。

## Open-book checklist 锚点(对 checks.md)

- §9 consumable_iap:目录逐字、grant 100、PDF 成功后扣 1、ExportRecord 含 transactionId、无 Restore —— `Models/Credits.swift` / `Store/CreditShopManager.swift` / `Export/ExportEngine.swift`。
- §12 camera:`Capture/CaptureSupport.swift` capture provider 抽象 + `-syntheticCapture` seam;拒绝分支无 Settings。
- §14/§15 缺席:`ThreadGridTests/AbsenceTests.swift`(4 测试);plist 无麦克风/ATT 键。
- §7 motion:5 moment_id ↔ MotionLanguage token/视图落点(见上);Reduce Motion 分支全量。
- §22 no_remote_ai:量化纯端上(`Imaging/ChartQuantizer.swift`),全仓零网络调用。
- §23 无 Settings 跳转:grep 零命中。
- §25 headless build:见下证据。

## Build & test evidence

- **Build**:`logs/build-5.log` — `xcodebuild`(外部 DerivedData `/tmp/ThreadGridDerivedData`)**BUILD SUCCEEDED**。
- **Full test suite**:`logs/test-final.log` — `xcodebuild test`(iPhone 16 Pro Max 2,最终提交代码)**18/18 pass,TEST SUCCEEDED**:16 unit(Absence 4 / Quantizer 5 / CreditCatalog 3 / PersistenceAndRender 4)+ 2 UI E2E(`testCreateChartThroughCameraSeam` 相机 seam 全旅程 49.3s、`testTabSwitchingRendersEveryRoot` 28.9s)。
- **Smoke 截图**:`logs/smoke_empty_state.png`(空态插画 + CTA)、`logs/smoke_home_with_chart.png`(hero + 图卡 + 进度环 + 4-tab)。
- **Git**:`30757b5 feat(threadgrid): rough_app attempt-1 — full SwiftUI atelier`,已推 origin/main(本地 == 远端)。

## Gaps

- 无阻塞缺口。记录两点对齐决策:
  1. **IAP 数值以 yanran.json 为唯一权威**(checklist §9 裁定):首启 grant=100、27 档逐字;PM 文案"grant 2 枚 / 5·15·40 档"未采用,shop UI 从逐字目录策划展示档位(标准 9 + 特惠 4),留给 PDA 对齐空间。
  2. Smoke 截图中图样名 "Photo chartSmoke Fox" 为 UI 测试向预填建议名("Photo chart")输入框直接键入的拼接产物;命名输入框用户可改,非产品文案缺陷。
- S3 跳过(remote_ai: no),无凭证密封,符合 checklist 备注。
