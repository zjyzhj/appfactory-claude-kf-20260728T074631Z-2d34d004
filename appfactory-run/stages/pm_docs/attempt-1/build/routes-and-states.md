# ThreadGrid · 路由与状态

导航壳:SwiftUI `TabView`,4 个 task-distinct 主 tab(Charts / Create / Stitch / Threads)。Settings 与 Credit Shop 从 Charts 导航栏进入(push/sheet)。每个 tab 对应一条端到端主任务并保持选中/进行中状态。

## Route 命名表(frozen)

| route_id | 归属 | 任务 | 主要状态 |
|---|---|---|---|
| tab_charts | Tab 1 | 图样库:浏览/搜索/筛选/新建入口 | loading / empty / list(按 status 分组) / error |
| chart_detail | push@charts | 单图样总览:进度、线量、动作入口 | viewing / confirming_delete |
| create_wizard | Tab 2(根) | 创建向导:source → tune → preview → save | pick_source / camera_capture / tuning / previewing / saving / denied_camera / denied_photo |
| chart_editor | push@charts|detail | 格点编辑:上色/替换/橡皮/撤销 | editing(pan/zoom/paint) / swapping_color / unsaved_changes |
| tab_stitch | Tab 3 | 选择/进入绣制对象;无 active 时引导 | no_active_chart / picking / ready |
| stitch_session | push@stitch | 逐格标记:过滤、高亮、进度 | stitching / symbol_filtered / finishing / finished_celebration |
| tab_threads | Tab 4 | DMC 色库 + 我的线 stash + 图样线量清单 | browsing_palette / stash_editing / chart_usage_view |
| chart_export | sheet@detail|editor|stitch | 导出:图卡(免费)/ 打印 PDF(1 Credit) | choosing_format / rendering / saved_to_photos / shared_pdf / insufficient_credits / denied_photo_write |
| credit_shop | sheet@export|settings | 消耗点数包购买(Export Credits) | browsing / purchasing / success / failed / insufficient_balance |
| settings | push@charts | 隐私说明、点数余额、关于 | viewing |

## 关键流转

- 空库 → tab_charts(empty 插画 + "Create your first chart")→ create_wizard。
- create_wizard save → chart_detail(新图,progress 0%)。
- chart_detail "Start stitching" → stitch_session(activeChartId 写入)。
- stitch_session 全部格标记 → finished_celebration → 可拍成品照(相机,record-bound)→ chart_detail finished。
- chart_detail/editor/stitch "Export" → chart_export;选 Printable PDF 且余额 0 → credit_shop → 购买成功回 chart_export 继续。
- 权限被拒(相机/相册读/相册写):原地展示该任务的替代入口(`Choose Photo` / `Add without a photo` / `Retry`),**永不出现 Open Settings 或跳系统设置**。

## 关键 en-US 反馈文案(copy intent)

| 场景 | 文案 |
|---|---|
| 空图样库 | "No charts yet — turn a photo into your first pattern." |
| 相机授权引导 | "Take a photo to stitch from. Camera stays on this device." |
| 相机被拒 | "Camera is off. You can still choose a photo from your library." (按钮: `Choose Photo` / `Not now`) |
| 相册读被拒 | "Photo access is off. You can start from a blank grid instead." (按钮: `Start Blank` / `Retry`) |
| 相册写被拒(导出) | "Couldn't save to Photos. You can share the image instead." (按钮: `Share` / `Retry`) |
| 生成完成 | "Your chart is ready — 40 colors, 120 × 160 stitches." |
| 标记进度 | (haptic 轻点)+ 进度环即时更新 |
| 完工 | "Finished! 18,432 stitches — nice work." |
| 点数不足 | "Printable charts use 1 Export Credit. Get more to print." (按钮: `Get Credits` / `Cancel`) |
| 购买成功 | "Credits added. Happy stitching!" |
| 删除确认 | "Delete this chart? Its stitching progress will be removed." |
| 通用错误 | "Something went wrong. Your work is saved — please try again."(细节仅记日志) |

## 状态红线

- 所有列表/编辑器操作即时持久化(本地);任何中断后重进恢复现场。
- 永不把原生错误文本展示给用户;权限流程符合 FinalGate non-branchable 规则(无 Settings 跳转、相机 record-bound、相册读写双声明)。
