# ThreadGrid · 视觉与动效

## 视觉方向

**"织物工作室"(atelier)**:温暖亚麻底 + 艾达布(Aida)格纹肌理 + 绣线色点缀。整体像一张铺开的绣绷,而不是又一个白底工具 App。

- 背景:全局暖亚麻色 `#F5EFE4`(亮)/ `#1D1A16`(暗,炭化亚麻);卡片用 `#FFFFFF`(亮)/`#2A251F`(暗)浮于其上;核心页面有完整主题背景,禁止裸露系统白。
- 格纹肌理:Charts/Create/Stitch 背景叠加 8% 透明度的细格网(呼应绣布);hero 区用手绘感针线插画。
- 主色(绣线红):`#C0453E`;辅色(靛蓝线):`#3E5F8A`;成功(艾草绿):`#5F8A4C`;警示:`#C8842C`。DMC 色卡以真实线色 hex 呈现,是本产品最"花"的部分,UI 其余部分克制。
- 字体:标题 rounded serif 气质(系统 `.serif` + `.rounded` design 组合可接受),正文 SF Pro;格点坐标/色号用 monospaced。
- 图标:SF Symbols + 少量自定义(针线/格点);导航图标语义化。
- 小屏红线:最小 320×568;格点编辑器最小可点格 ≥ 14pt(双指缩放可达 44pt);长内容一律 ScrollView;无硬编码页面高度。

## In-app image slots (required)

| slot_id | kind | route_id | component | purpose | asset_or_source | empty_fallback | acc_ids |
|---------|------|----------|-----------|---------|-----------------|----------------|---------|
| app_icon | app_icon | n/a(system) | Asset Catalog imageset | 品牌图标:针穿格点 | bundle asset | n/a | ACC-VIS-ICON |
| charts_hero | hero | tab_charts | `Image`(asset)+ 标题叠层 | 首屏品牌 hero:针线穿过格点的主题插画区,约占首屏 30–40% | bundle asset(主题插画) | 纯亚麻底 + 主色丝线 SVG/SF Symbol `rectangle.grid.3x3` | ACC-VIS-HERO |
| charts_empty_illustration | empty_illustration | tab_charts | `Image`(asset) | 空库插画:空绣绷 + 引导文案 | bundle asset | SF Symbol `photo.on.rectangle` + 主色圆底 | ACC-VIS-EMPTY |
| create_source_photo | photo_or_media | create_wizard | `Image`(uiImage)/ PhotosPicker thumbnail | 创建向导的源照片预览区(占预览屏 40–60%),转图前后对比 | 用户相机/相册 | 主色占位 + `camera` SF Symbol | ACC-VIS-MEDIA |
| chart_thumbnail | photo_or_media | chart_detail / tab_charts | 格点渲染视图(Canvas)| 图样缩略:真实格点渲染(非 SF Symbol),详情页大图 30–50% | 运行时格点渲染 + 可选源照片角标 | 灰格 + 进度 0% 渲染 | ACC-VIS-MEDIA |
| finished_piece_photo | photo_or_media | chart_detail / stitch_session | `Image`(uiImage) | 完工成品照(F7),详情页与图卡共用 | 用户相机/相册 | 无照片时不渲染该区块(非必需) | ACC-VIS-MEDIA |

规则:slot 全部唯一;每个 slot 在对应 route 有真实 SwiftUI 视图;empty_fallback 必现;photo/media 三个 slot 走真实用户媒体路径。

## Motion & interaction language (required)

### Motion thesis
像拉一根绣线穿过布面:所有动效短、轻、带"线被拉紧后回弹"的手感——创作与标记的每一步都被温柔确认,绝不打断手作节奏。

### Shared motion tokens
| token | value | usage |
|-------|-------|-------|
| threadEase | 0.35s `easeOut` | 通用进场/状态切换 |
| pullSpring | `spring(response: 0.4, dampingFraction: 0.7)` | 格点标记、按钮回弹 |
| weaveStagger | 0.03s/项 | 列表/格带逐行进场 |
| celebrateDuration | 1.2s | 完工描边动画 |

### Product moments
| moment_id | route_id | trigger | user_value | motion_behavior | haptic | reduce_motion_equivalent | acc_id |
|-----------|----------|---------|------------|-----------------|--------|--------------------------|--------|
| mot_entry_weave | tab_charts | 冷启动/回库首帧 | 明确"回到我的绣架" | hero 插画淡入 + 图样卡按 weaveStagger 逐行织入 | 无 | 直接静态呈现,内容即时可读 | ACC-MOT-ENTRY |
| mot_commit_stitch | stitch_session | 标记/取消一格 | 每一针都有确认感 | 格子以 pullSpring 缩放 1→1.15→1 + 色块晕开;进度环 threadEase 推进 | `.light` 单点 | 格子即时变色 + 进度数字变化,无缩放动画 | ACC-MOT-COMMIT |
| mot_success_finish | stitch_session | 最后一格标记完成 | 完工仪式感 | 图样外框以 celebrateDuration 描边"缝合一圈" + 彩纸微粒子 | `.success` 通知触感 | 静态完工横幅 + 进度 100%,无粒子 | ACC-MOT-SUCCESS |
| mot_empty_guide | tab_charts | 空库/空过滤结果 | 空态不冷场 | 空绣绷插画 2.5s 呼吸浮动(±4pt) | 无 | 静态插画 + 引导按钮 | ACC-MOT-EMPTY |
| mot_export_pull | chart_export | 导出成功(图卡/PDF) | "成品离手"的确认 | 卡片从预览位向上"抽线"滑出 + 对勾浮现 | `.medium` | 直接显示成功横幅 | ACC-MOT-SUCCESS |

### Forbidden
- 禁止全屏 lottie 式喧宾动效;禁止格点编辑器内任何自动播放动画(手作时眼睛要休息)。
- 禁止 modal 之间连续弹簧(一次只弹一个对象);禁止旋转 loading 超过 0.5s 无进度说明。
- 不与近期包动效撞车:不用 ReadyAt 的"时间线错峰",不用 TourWise 的"权重滑杆"——本包一切动效围绕"线/格/缝合"。

## Visual frames(for pm_visuals;inventory truth,≤6)

| frame_id | route_id | purpose | layout skeleton | density | avoid |
|----------|----------|---------|-----------------|---------|-------|
| frame_charts_home | tab_charts | 首屏:hero + 图样卡列表(含进度环) | 顶部 hero 插画区 → 状态分组 → 卡片两行网格/列表 | 中 | 白底裸列表 |
| frame_charts_empty | tab_charts | 空库引导 | 居中插画 + 一句文案 + 主按钮 | 低 | 纯文字空态 |
| frame_create_preview | create_wizard | 照片→格点预览对比 | 上源照片下格点预览(或左右)→ 底部尺寸/色数控件 | 中高 | 无照片占位空屏 |
| frame_chart_editor | chart_editor | 编辑器:格点画布 + 底部 DMC 色板条 | 全幅画布 + 底部色板/符号条 + 顶部撤销 | 高 | 编辑器像表格 |
| frame_stitch_session | stitch_session | 绣制:格点 + 当前色高亮 + 进度环 | 画布 + 顶部进度环 + 底部当前线 chip 条 | 高 | 与编辑器视觉无区分 |
| frame_chart_export | chart_export | 导出:图卡预览 + PDF 选项 + 点数余额 | 顶部图卡预览 → 两个格式卡 → 底部余额行 | 中 | 三档订阅式 paywall 文案 |

pm_visuals 可按 slot_id 额外产出 `slots/<slot_id>.png` 可嵌入位图(无 UI chrome)。

## 可访问性

- 全部交互元素 ≥44pt;格点编辑/绣制支持双指缩放至单格 ≥24pt。
- 色彩不单独承载语义:绣制过滤同时显示符号;DMC 色块必带色号文字。
- Dynamic Type 到 AX3 不截断关键按钮;Reduce Motion 走上表等价路径;VoiceOver:格子读出"row 12, column 34, DMC 310, stitched"。
