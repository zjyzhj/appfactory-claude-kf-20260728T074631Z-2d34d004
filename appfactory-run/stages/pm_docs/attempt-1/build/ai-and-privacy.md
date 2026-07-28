# ThreadGrid · AI、隐私与商业化

## AI implementation card
- remote_ai: no
- pattern_id: none
- surface: n/a(无 AI 界面)
- primary_cta: n/a
- result_ui: n/a
- access_model: none
- access_detail: no remote AI;照片转格点图为端上确定性色彩量化(中位切分映射 DMC 色域)
- why_not_P1: n/a(无远程 AI);核心 job 是确定性图像处理,远程 AI 不能 materially improve,反而破坏"照片不出设备"的卖点
- near_neighbor_diff: 近期邻居 ReadyAt(remote_ai=yes, P4 Suggest Steps 烹饪步骤草稿)/ TourWise(remote_ai=no)。本包为 no-remote,与 TourWise 同桶但交互骨架(creation_tool vs decision_assistant)、付费对象(打印导出 vs 结论卡)与全部文案零重叠;无任何 AI 表面可与 ReadyAt 撞车。

## Commerce card
- iap: required (yanran)
- money_value: **可打印图解 PDF 导出**(多页符号图 + DMC 线量清单 + 色符对照)——按幅付费的手作节奏;应用内全部创作/绣制功能免费,成果图卡(保存相册/分享)免费
- paywall_hook: chart_export 选择 Printable PDF 且余额为 0 时 → credit_shop;settings 余额行 → credit_shop
- entitlement_model: consumable(yanran balance catalog:Export Credits 点数包;首启 grant 2 枚,之后按包购买,如 5/15/40 枚档)
- restore: no(消耗品不暴露 Restore Purchases 流程或字样)
- why_not_factory_default: 不是"1 次免费 AI 然后 AI Unlock"——本包无 AI;付费对象是按份消耗的实物产出(打印图解),首启赠送 2 枚,免费层不残废(创作/绣制/图卡导出全免费)

## Privacy

- 零账号、零云同步、零第三方分析 SDK(v0);照片与图样仅存应用沙盒。
- 权限(JIT、record-bound):
  - `NSCameraUsageDescription`:"Take a photo to turn into a stitch chart, or snap your finished piece. Photos stay on this device."
  - `NSPhotoLibraryUsageDescription`:"Pick a photo from your library to convert into a stitch chart. Photos are only read on this device."
  - `NSPhotoLibraryAddUsageDescription`:"Save your stitched result card to Photos so you can print or share it."
- 权限被拒:全部应用内继续(Choose Photo / Start Blank / Share / Retry),**无 Open Settings、无 openSettingsURLString**。
- ATT:不请求(无跟踪、无广告);麦克风:不使用。Privacy manifest 按实际(仅 UserDefaults/文件时间戳等必要项)声明。
- 隐私说明入口:settings 一页,说明数据全本地、如何删除(删 Chart 级联清理;删 App 即全清)。

## App Review risk card (required)

| guideline | risk_for_this_product | mitigation_in_package | proving_finalgate_check | acc_id |
|-----------|-----------------------|-----------------------|--------------------------|--------|
| 2.1 App Completeness | 格子编辑器/绣制模式若只做半吊子会像 demo | F1–F12 全链路可执行:创建→编辑→绣制→导出闭环,无占位符;权限拒绝路径完整 | product_maturity:core_value_and_feature_completeness | ACC-REV-COMPLETE |
| 4.2 Minimum Functionality | "照片转格子"单功能可能被读成太窄 | 窄而完整:编辑器(F4)、进度跟踪(F6)、DMC 线库与 stash(F8)、打印导出(F10)构成持久复用手作工作流,非一次性转换器;图样库与进度是回访资产 | product_maturity:feature_expansion | ACC-REV-MINFUNC |
| 4.3 Spam / Repeat | 与近期工厂包及商店克隆的相似性 | dedupe 记录:creation_tool/cross-stitch-craft 与 TourWise(decision_assistant/房产)、ReadyAt(action_tool/烹饪)无重叠;与商店 color-by-number 游戏不同类目不同 job;详见 §市场供给与立场 | (dedupe record; no check_id) | ACC-REV-DIFF |
| 5.1.1 Data Minimization | 相机/相册权限过度索取风险 | 三个权限全部 JIT + record-bound + 产品化文案;零账号零上传;拒绝路径应用内继续;隐私页可直达 | ios_delivery:camera_permission / ios_delivery:photo_library_read_write_permission | ACC-REV-PRIVACY |
| 3.1.1 In-App Purchase | 实物相关/解锁模式误判 | 仅 StoreKit 消耗型点数(Export Credits)购买数字导出服务;无外部支付、无实物商品、无订阅、无 Restore UI | ios_delivery:consumable_iap | ACC-REV-IAP |

### Review notes
- 审核员可能试"不授权相册":v0 必须能从空白格子完整走通(F3),这是 4.2 的保险。
- PDF 导出是纯数字内容,走 IAP 消耗品;成果图卡免费,避免"什么都要钱"的观感。
- 4.3 依赖 dedupe store 本 run 提交记录;不与任何近期包共享骨架/领域/AI 形态。
