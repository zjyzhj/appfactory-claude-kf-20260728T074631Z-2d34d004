# Checklist · ThreadGrid

- Standard: /Volumes/zjySD/claude-app-factory/runs/kf-20260728T074631Z-2d34d004/stages/pm_docs/attempt-1/MAP.md
- Policy: agents/FinalGateAgent/direct-repo-required-checks.json (policy_version 2.12.0, sha256 c2ebf538a5c0c4e1385ee84bb1fe229ccbd1c30ea66aba4b24f3bd751babbcda)
- Evidence classes: agents/FinalGateAgent/check-evidence-classes.json (sha256 7e64af7dba7aaebc061663f5e6fb16483c3da49655dec928ea17b50a4db065c7)
- Data contracts: agents/FinalGateAgent/data-contracts/iap/yanran.json (sha256 b6b737cedfcec27d9104ffc4fb60e2c23479a7c2bcf6dec6bf14983959e60790)
- Acceptance policy: runtime_verification_required (ref runs/kf-20260728T074631Z-2d34d004/acceptance_policy.v1.json, sha256 cb56b5d7daa90d2173a7d2eb10d6b10329b123f1b668f599ee933660c911651e; evidence_skill ios_runtime_acceptance; simulator_runtime REQUIRED) — runtime_hard check 在 verification 阶段必须带真实 Simulator 证据方可 pass
- Checks: ./checks.md
- Status: ready

## 清单概览

- A. 政策 required set 17 条(checks.md §1–§17),含全部 required=true check_id,`functional_completeness_final_review` 排最后;无省略、无弱化、无 not_in_checklist。
- B. PM 图像 slot 4 条(§18–§21):app_icon / charts_hero / charts_empty_illustration / photo_or_media(三 slot)。
- C. PM 派生 4 条(§22–§25):no_remote_ai 边界、权限拒绝无 Settings、4.3 dedupe 信息性引用、可选 headless build。

## 政策分支裁定(无冲突)

- IAP:PM 消耗制 Export Credits 与 yanran 余额目录一致——**无 checklist_policy_iap_model_conflict**;首启赠送/档位数值以 yanran.json 为唯一权威,PM 文案(grant 2 枚、5/15/40 档)若冲突由 PDA 对齐目录。
- 麦克风:缺席分支——能力图无音频工作流,要求四条硬缺席证明(plist 无键 / 无录音 API / 聚焦缺席测试 / runtime 零弹窗)。
- ATT:缺席分支——零分析零跟踪,证明集含 PrivacyInfo `NSPrivacyTracking=false`。
- 相机/相册读写:record-bound JIT + 双声明齐全,PM 与政策同向;无 Settings 跳转已写入 §23。
- 导航:4-tab `TabView` 满足 3–5 底部 Tab 要求,非单薄产品,无 single-surface 例外诉求。
- App Review 风险卡:ACC-REV-* 各行映射到既有 policy id(2.1→core_value、4.2→feature_expansion、5.1.1→camera/photo、3.1.1→consumable_iap),不新增 check_id;4.3 走 dedupe 记录(§24 信息性)。

## 给 rough_app / PDA 的 open-book 要点

- 按 checks.md 每条的「源码静默证明」构建;runtime_hard 条目的「Simulator 复现路径」即 L1 行为脚本。
- PackageDelivery MAP 必须含 `## Feature expansion consumption` 与 `## Functional completeness final review` 两个 JSON manifest(§2、§17)。
- 相机必须提供 Simulator 确定性捕获替代 seam(§12),否则相机链无法 PASS。
- 动效 pass 证据必须映射 5 个 moment_id + 三观察点 + Reduce Motion 等价(§7)。
