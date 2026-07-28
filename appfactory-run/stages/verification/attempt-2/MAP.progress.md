# Verification progress · ThreadGrid (attempt 2 · regression + final pass)
- Mode: runtime_verification_required
- Repo HEAD: b2de9da (patch 7fd1325 已在 main)
- Bug bus: b-14320aed1ab3 merged (待本 attempt 回归转 verified)
- Checks (回归范围 + final pass):
  - ios_delivery:consumable_iap: pending — patch 源码复核已完成(diff/6单测/UI smoke 均真实有效);等待 fresh build+test 结果
  - export_route_smoke: pending — UI 路由测试 testPDFExportRouteRecordsFundingTransaction 含真实路由+readback 断言;等待 fresh 运行
  - final_full_pass(24 条 attempt-1 已 pass): pending — 未触达区域复用 attempt-1 hash-bound 证据,patch 触达面新采
