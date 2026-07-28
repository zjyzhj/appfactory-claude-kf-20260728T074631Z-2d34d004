# ThreadGrid · 功能清单(F1…F12)

| id | 功能 | 描述 | 成功信号 | 相关 route |
|---|---|---|---|---|
| F1 | 图样库 | 按 status(draft/active/finished)分组列表、搜索、缩略图(渲染格点图,非源照片)、新建入口、空态插画 | 空库 30 秒内到首个 Chart 创建;列表即时刷新;缩略图为真实格点渲染 | tab_charts |
| F2 | 照片转图样 | 相机拍摄或相册导入照片 → 选格数(30–200)与色数(4–60)→ 端上色彩量化到 DMC 色域 → 预览 | 60 秒内照片→预览;预览格点可缩放;无网络请求 | create_wizard |
| F3 | 空白起稿 | 无照片时建空白格点图,编辑器手画 | denied_photo 状态下可全程完成 | create_wizard → chart_editor |
| F4 | 格点编辑器 | 逐格上色、整色替换、橡皮、撤销/重做、双指缩放平移、DMC 色板选择、符号联动显示 | 每次修改即时持久化;undo 栈 ≥20 步;色块替换后 stitchCount 同步 | chart_editor |
| F5 | 图样总览 | 进度环、状态流转(draft→active→finished)、线量清单入口、动作(Stitch/Edit/Export/Delete) | 进度环与 stitch_session 标记实时一致;删除有确认并级联清理 | chart_detail |
| F6 | 绣制模式 | 逐格标记/取消、按颜色或符号过滤高亮、"当前线"模式、进度环、完工检测 | 标记有 haptic + 动效;过滤时仅当前色格高亮;全格标记触发完工流 | stitch_session, tab_stitch |
| F7 | 成品照 | 完工后相机拍或相册选一张成品照绑定 Chart(record-bound 捕获) | 成品照显示于 chart_detail 与图卡;相机被拒可跳过 | stitch_session(finished_celebration), chart_detail |
| F8 | DMC 色库 + Stash | 浏览 DMC 色卡、按色号搜索、标记拥有绞数;图样线量清单(join 缺线高亮) | 清单 stitchCount/估算绞数与 Chart 一致;缺线视觉可辨 | tab_threads, chart_detail |
| F9 | 导出图卡 | 生成成果图卡(格点渲染 + 标题 + 进度/完工日期 + 可选成品照),保存到相册或系统分享;免费 | 图卡落入相册;相册写被拒时提供 Share 替代,无 Settings 跳转 | chart_export |
| F10 | 打印图解 PDF | 多页 PDF:符号格点图 + DMC 线量清单 + 色符对照表;每份消耗 1 Export Credit | 余额扣减与 ExportRecord 一致;余额 0 引导 credit_shop | chart_export, credit_shop |
| F11 | Export Credits(yanran 消耗制) | 点数包购买、余额展示、消费流水;首启 grant 2 枚;无 Restore Purchases | 购买成功余额即时增加;流水含 storekitTransactionId;UI 无 restore 字样 | credit_shop, settings |
| F12 | 权限与隐私 | 相机/相册读/相册写 JIT 请求,产品化用途文案;被拒全部应用内继续;隐私说明页 | 三条拒绝路径均有任务替代入口;无 Open Settings 文案/调用 | create_wizard, chart_export, settings |

## 范围注记

- 全部功能离线可用;无推送、无账号、无分析 SDK(v0)。
- F2 的量化算法为端上确定性实现(中位切分或等价),不调远程服务。
