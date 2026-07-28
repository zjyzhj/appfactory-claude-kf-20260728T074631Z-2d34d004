# ThreadGrid · 验收(ACC)

可静默验证的观测条件为主;route_id 与 features/ACC 一一对应。

## 功能 ACC

| acc_id | route_id | 可观测通过条件 |
|---|---|---|
| ACC-001 | tab_charts | 空库时显示 charts_empty_illustration + "Create your first chart" 主按钮;点击进入 create_wizard |
| ACC-002 | create_wizard | 相册选图 → 预览格点图出现;尺寸/色数调节实时重渲染;保存后 tab_charts 出现新 Chart |
| ACC-003 | create_wizard | 相机入口存在;拒绝授权后出现 `Choose Photo`/`Start Blank` 应用内继续入口,无 Settings 跳转 |
| ACC-004 | chart_editor | 点格上色即时可见;整色替换后所有该色格更新;撤销恢复上一状态;杀进程重进数据仍在 |
| ACC-005 | stitch_session | 标记格子后进度环前进;按色过滤仅高亮当前色;最后一格触发完工流 |
| ACC-006 | stitch_session | 完工后可拍/选成品照并显示于 chart_detail;拒绝相机可跳过且不阻塞完工 |
| ACC-007 | tab_threads | DMC 色库可搜索;stash 标记绞数后图样线量清单缺线高亮更新 |
| ACC-008 | chart_export | 图卡可保存到相册(写权限);拒绝相册写时提供 `Share`/`Retry`,无 Settings 跳转 |
| ACC-009 | chart_export | Printable PDF 导出扣减 1 Credit 并生成 ExportRecord;余额 0 时引导 credit_shop |
| ACC-010 | credit_shop | 购买点数包成功后余额即时增加;流水含 storekitTransactionId;全 App 无 Restore Purchases 字样 |
| ACC-011 | settings | 隐私说明页可达,明示数据全本地;余额行可进 credit_shop |
| ACC-012 | tab_charts | 删除 Chart 有确认;确认后列表移除且沙盒照片副本清理 |

## 视觉 slot ACC(必备)

| acc_id | route_id | 可观测通过条件 |
|---|---|---|
| ACC-VIS-ICON | n/a | App Icon asset 存在且被 Info/Assets 引用,非默认空白图标 |
| ACC-VIS-HERO | tab_charts | charts_hero 视图存在于首屏源码,空/有数据时均有品牌视觉(图或 fallback) |
| ACC-VIS-EMPTY | tab_charts | 空库时 charts_empty_illustration 可见,含 fallback 路径 |
| ACC-VIS-MEDIA | create_wizard / chart_detail | create_source_photo 与 chart_thumbnail 为真实图像/格点渲染表面;有用户照片时显示真实照片 |

## 动效 ACC(必备)

| acc_id | route_id | 可观测通过条件 |
|---|---|---|
| ACC-MOT-ENTRY | tab_charts | 首屏 hero + 卡片按声明的 weaveStagger 织入(或 Reduce Motion 下静态即时呈现) |
| ACC-MOT-COMMIT | stitch_session | 标记格子使用 pullSpring + light haptic;进度环 threadEase 推进 |
| ACC-MOT-SUCCESS | stitch_session / chart_export | 完工描边"缝合一圈" + success haptic;导出成功"抽线"动画或对勾横幅 |
| ACC-MOT-EMPTY | tab_charts | 空态插画呼吸浮动(Reduce Motion 下静态) |
| ACC-MOT-REDUCE | 全局 | 开启 Reduce Motion 后,上述 user_value(确认感/进度/完工反馈)全部以非动画等价保留 |

## App Review ACC(必备)

| acc_id | route_id | 可观测通过条件 |
|---|---|---|
| ACC-REV-COMPLETE | 全链路 | 创建→编辑→绣制→导出在 Sources 中端到端存在;无 placeholder/demo 主流程 |
| ACC-REV-MINFUNC | tab_charts…chart_export | 功能集提供持久独立价值:图样库 + 编辑器 + 进度 + 线库 + 导出均可用,非包装页 |
| ACC-REV-DIFF | n/a | dedupe store 本 run 记录与近期包(房产/烹饪)骨架领域均不同 |
| ACC-REV-PRIVACY | create_wizard / chart_export / settings | 三个权限声明产品化且最小;无未声明权限;隐私入口可达;拒绝路径全部应用内继续 |
| ACC-REV-IAP | credit_shop / chart_export | yanran 消耗型点数购买链路连通;无 Restore Purchases UI;paywall 与 commerce card 一致 |
