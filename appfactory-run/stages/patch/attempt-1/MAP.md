# PackageDelivery · patch

- Status: ready
- Repo: /Volumes/zjySD/claude-app-factory/runs/kf-20260728T074631Z-2d34d004/product (origin: zjyzhj/appfactory-claude-kf-20260728T074631Z-2d34d004, branch main)
- From verification: /Volumes/zjySD/claude-app-factory/runs/kf-20260728T074631Z-2d34d004/stages/verification/attempt-1/MAP.md
- Bug bus: /Volumes/zjySD/claude-app-factory/runs/kf-20260728T074631Z-2d34d004/qa/bugs.jsonl (assigned: b-14320aed1ab3 → merged)
- Failed ids in: ios_delivery:consumable_iap

## 修复摘要(zh-CN)

按 verification 指引做最小 diff,只动 write_scope 内 3 个源文件 + 测试 target,未触碰其余已验证 IAP 链路(27 档目录、verified 校验入账、扣点后移、零 Restore 均未改)。

1. `ThreadGrid/Models/Credits.swift`:`ExportRecord` 新增可选 `storekitTransactionId: String?`(可选字段经 `decodeIfPresent` 解码,旧记录无该键不崩);`CreditLedger` 新增 `fundingStorekitTransactionIdForNextSpend`——购买余额先于赠送余额消耗,未花完的购买余额存在时归属最近一次购买的 StoreKit transaction id,纯赠送出资返回 nil(注释说明)。
2. `ThreadGrid/App/AppStore.swift`:`recordExport` 增加 `storekitTransactionId` 可选参数(默认 nil,旧调用点零改动);新增 `fundingStorekitTransactionIdForNextSpend` 访问器。
3. `ThreadGrid/Views/Export/ChartExportView.swift`:`exportPDF` 在扣点前先取出资交易 id,扣点后随 ExportRecord 落盘;图卡导出免费、无扣点,不做归属(维持原调用)。
4. 测试:`ThreadGridTests/ExportFundingTests.swift` 6 条聚焦单测(购买出资回填、赠送出资 nil、免费图卡 nil、购买耗尽回退 nil、旧格式 ExportRecord 解码、旧格式 PersistedState 整包解码);`ThreadGridUITests` 新增 `testPDFExportRouteRecordsFundingTransaction`——测试内用 App 自身 Codable 模型生成的种子 store.json(含 1 张图样 + 一笔 `smoke-funding-txn-001` 购买流水)注入 Simulator 容器,走真实 UI 路由(图库→详情→Export→Printable Chart PDF)导出 PDF,再测试内 readback 持久化 store.json 断言 ExportRecord 携带出资交易 id 且余额 210→209。

注意点:种子 `activeChartId` 必须置空——首版种子带上它会让 Stitch tab 自动开绣制会话,导致既有 `testTabSwitchingRendersEveryRoot` 的空态/选图断言失败(已修正,全套回归通过)。

## Patched

| bug_id | check_id | change | commit |
|--------|----------|--------|--------|
| b-14320aed1ab3 | ios_delivery:consumable_iap | ExportRecord 加可选 storekitTransactionId + PDF 扣点路径回填出资交易 id + 兼容解码 + 6 条聚焦单测 + 1 条 Simulator 导出路由 UI smoke | 7fd1325 (main, 已 push) |

## 验证证据

- 全套测试:22 单测 + 3 UI E2E 全绿(headless xcodebuild,iPhone SE 2nd gen 9D366A61-1AD6-4232-B749-808F902EFACA,DerivedData /tmp/appfactory-derived-kf-2d34d004-patch,result bundle /tmp/tg-patch-seed/smoke.xcresult)
- 导出路由 smoke readback:`./evidence/readback-store-after-pdf-export.json`(sha256 41a3783a…)——ExportRecord{kind: printable_pdf, storekitTransactionId: "smoke-funding-txn-001", chartId 匹配},ledger.balance=209
- 种子输入:`./evidence/seed-store.json`(sha256 171a7f5b…,由真实 Chart/Credits 模型编码生成)
- Bug bus:b-14320aed1ab3 已置 merged(待 QA 回归转 verified)

## Still open

- none(回归指引见 verification MAP:重评 ios_delivery:consumable_iap + 导出路由 smoke,本 stage 已先跑过一次该 smoke 并留 readback 证据)

## Gaps / blockers

- none
