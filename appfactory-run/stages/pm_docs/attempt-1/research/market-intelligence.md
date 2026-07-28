# Market intelligence

run: kf-20260728T074631Z-2d34d004 · stage: pm_docs · attempt 1 · 2026-07-28

## Candidate set

| candidate_id | one-line pitch | category_skeleton | domain_cluster | appstore_scan_verdict | demand_radar_evidence | value_score_total | status |
|---|---|---|---|---|---|---|---|
| c1_stitchgrid | 照片转十字绣格点图 + DMC 线色 + 逐格进度 + 可打印导出 | creation_tool | cross-stitch-craft | proceed_narrow_wedge(PMAgent 证据化修正;原脚本 reject_saturated_clone 系把 color-by-number 游戏与 0 评分僵尸误计为克隆) | yes(research/demand-radar/cross-stitch-mobile.md,high) | 22 | survivor → **selected** |
| c3_cubecoach | 相机扫魔方 → 引导求解 → 算法 drill 训练器 | game_skill | rubiks-cube-training | proceed_narrow_wedge | yes(research/demand-radar/rubiks-cube-learn.md,high) | 20 | survivor |
| c2_luxspot | 相机测光 + 家庭点位地图 + 植物摆位匹配 | camera_sensor_live | home-plant-care | reject_saturated_clone(Photone 4875 rc 精确占位该 wedge) | no | — | rejected |
| c4_paintpale | 相机取色 + 配色和谐工作室 + 色卡导出 | creation_tool | home-paint-color | reject_saturated_clone(Color Portfolio/Coolors/Adobe Capture/品牌 App 合围) | no | — | rejected |
| c5_chordpress | 吉他和弦谱/歌词谱创作 + 移调 + PDF | creation_tool | music-chord-sheets | reject_saturated_clone(Ultimate Guitar 467k rc 护城河) | no | — | rejected |
| c6_quiltgrid | 拼布 block/布局设计 + 布料计算 + 图样导出 | creation_tool | quilting-design | reject_saturated_clone(CREATIVATE 等在位 + 头部占位) | no | — | rejected |
| c7_cutmap | 木工下料优化:板件排样图 + 余料管理 | action_tool | woodworking-cutlist | reject_saturated_clone(CutFlow 等优化器扎堆) | no | — | rejected |

候选集 7 个(≥4 达标)。骨架刻意分散:creation×3、camera_sensor_live×1、game_skill×1、action_tool×1(去重记忆见下)。

## App Store scan verdicts

- c1_stitchgrid: `proceed_narrow_wedge`(修正后)。修正全文与逐条 trackId 重新分类见 `research/appstore-scan/c1_stitchgrid.md` §PMAgent refinement:真实功能性竞争者仅 Stitchly(1467867656,2052 rc)、Markup R-XP(1559524491,2733 rc,2024-04 停更)、Magic Needle(1323730066,1120 rc)、XStitch Plus(1281394467,1015 rc);keyword 空间拥挤来自 color-by-number 游戏(非本 job)。wedge_vs_top_n 非空,见 scan 文件。
- c3_cubecoach: `proceed_narrow_wedge`。collision med(active L2=23、L3=0);头部 ASolver(1604603007? 见 scan 原始表)/Cube Solver 3D(1673039373,241450 rc)/21Moves(1533263247)体量大但一星集中在扫描不准与无教学。wedge_vs_top_n 见 `research/appstore-scan/c3_cubecoach.md`。
- c2_luxspot: `reject_saturated_clone`(Photone 1450079523 4875 rc + LM-3000 + Lux Pro 系列 + Planta/PlantIn 巨头)。drop。
- c4_paintpale: `reject_saturated_clone`。drop。
- c5_chordpress: `reject_saturated_clone`(Ultimate Guitar 357828853 467810 rc)。drop。
- c6_quiltgrid: `reject_saturated_clone`。drop。
- c7_cutmap: `reject_saturated_clone`。drop。

## Demand radar

- c1_stitchgrid: `research/demand-radar/cross-stitch-mobile.md`(signal high)。关键 verbatim:"Symbol detection is extremely inconsistent rendering the app as useless."(Markup R-XP);"paying for a subscription with no updates in two years is a joke";"when I import a PDF pattern, it just crashes"(Stitchly);Pattern Keeper 无 iOS 版(iTunes search 无结果)。demand_evidence_refs 已记入候选卡。
- c3_cubecoach: `research/demand-radar/rubiks-cube-learn.md`(signal high)。"it keeps saying incorrect when it's correct";"I'm a complete beginner and it doesn't have visual directions";"I literally can't find a single Rubik's cube solver app that ... (isn't) paying in game transactions"。
- 搜索方式说明:无 `bl`/DASHSCOPE 与 Reddit 直连;证据来自 Apple 官方 iTunes customerreviews RSS(可达)与 crewelghoul.com 评测,逐条 URL 在卡片内。

## Value score

| candidate_id | market_depth | differentiation_room | v0_aha | novelty | iteration_runway | total | deciding_axes |
|---|---|---|---|---|---|---|---|
| c1_stitchgrid | 4 | 4 | 4 | 5 | 5 | 22 | novelty + iteration_runway + differentiation_room 三轴齐高;在位者弱点是手艺/维护 |
| c3_cubecoach | 5 | 3 | 4 | 4 | 4 | 20 | market_depth 最高,但 differentiation_room 被在位巨头体量压到 3 |

逐轴单行说明:c1 五轴无短板且 wedge 不依赖技术奇迹;c3 的 market_depth(5)被 differentiation_room(3)与同族骨架新颖度(4)抵消。完整版见 `research/value-score.md`。

## Memory check (novelty vs recent deliveries)

- `~/.claude/app-factory/pmagent_objective_history.jsonl`:**history file missing — assumed empty**(按契约处理并在此声明)。
- 旁证:`dedupe_list` + `pm_docs_global_idea_memory.jsonl` + 批次 ledger 显示近期已交付:TourWise(2026-07-27,decision_assistant,housing-viewing)、ReadyAt(2026-07-27,action_tool,cooking-meal)、Waitwise(2026-07-26,game_skill,mahjong,run 目录可见)。
- 逐候选检查(规则化执行,lookback 因 history 缺失以 dedupe/记忆文件等效窗口替代):
  - c1_stitchgrid (creation_tool, cross-stitch-craft):无任何同 pair;creation_tool 骨架近期未使用 → novelty 不扣分(5)。
  - c3_cubecoach (game_skill, rubiks-cube-training):同 pair 无;**同 skeleton(game_skill)不同 domain 且落在最近窗口(Waitwise,07-26)** → novelty -1(4)。
  - c2/c4/c5/c6/c7:均已 reject,不参与打分;其中 c7 action_tool 与 ReadyAt 同族,c4/c5/c6 creation_tool 与 c1 同族但均未出线。
- 结论:共检视 3 条近期交付(等效窗口),发现 1 个同族不同域近邻(c3 vs Waitwise),c3 novelty 由 5 调整为 4;c1 无调整。

# Red-team notes

### c1_stitchgrid

- **Skeptical CEO**:90 天后有没有人回访?绣一幅中等图样要几周到几个月,进度标记是天然的周级回访钩子;绣完一幅会开下一幅(图样库 + 再做)。它值得存在,因为 iOS 上"可信的图样工作室"这个位置今天是空的:Stitchly 会崩、Markup R-XP 停更收订阅、Pattern Keeper 根本不来 iOS。我敢承认这是我批的。
- **User Researcher**:具体时刻——绣友晚上在沙发上,手机里存了一张宠物照片想绣成图,打开 Stitchly 导入即崩溃;或者绣到一半用 Markup R-XP 标记,符号识别把相邻符号一起高亮,她失去对进度的信任。次优解是网页版 Stitch Fiddle(浏览器里捏小格子)+ 纸质打印打勾,代价是每幅图多花一两小时清理颜色,且进度全靠纸。
- **Compete Analyst**:Top-N 填不掉这个洞:游戏类不是工具;Stitchly 的崩溃与尺寸上限是评论区的常驻;Markup R-XP 绑定 PDF 符号识别这条技术路线,两年没更新。拿掉我们的 wedge(可靠的本地创建→绣制→打印一体、DMC 真色)后不会塌成 clone——因为在位者没有一家同时做到这三段;我们做全链路这件事本身就是差异。
- **Taste Editor**:aha 够锋利:导入一张照片,30 秒内变成一张可编辑、可打印、逐格可标记的 DMC 格点图——"我的照片变成了绣图"是有情绪的时刻。格点编辑器 + 织物质感视觉不是换皮记录模板;核心交互是"在格子上作画/标记",与任何 log_record_archive 无关。

### c3_cubecoach

- **Skeptical CEO**:需求巨大(评分量数十万),学会魔方的人确实会回来 drill 和计时。但回访理由和在位者高度同质——我必须回答"为什么用户放着 24 万评分的 Cube Solver 3D 不用",答案(扫描更准 + 有教学 + 无广告)每一条都要做到显著更好才成立。
- **User Researcher**:具体时刻——孩子(或新手)把魔方拧乱,扫了三次 app 都说颜色不对,气得放弃。次优解是看 YouTube 层先法教程 + 纸质公式卡,代价是没人陪他校验"我这一步做对没有"。这个痛是真的。
- **Compete Analyst**:洞存在(教学 + 可校验求解),但 Top-N 不是填不掉而是"犯懒没填":它们任何一次大更新都能加教学模块。我们的 wedge 中"扫描更准"依赖在端上 CV 做得比 24 万评分的对手好——这是技术奇迹赌注,不是结构性空位。拿掉扫描优势,我们就塌成又一个 solver clone。
- **Taste Editor**:分步检查点("现在你的魔方应该长这样")是有 craft 的;但整体仍是"求解器+计时器"的熟悉配方,aha 的锋利度依赖扫描成功率这个不可控变量。

# Bet statements

- **c1_stitchgrid**:我们押 c1 能赢,因为 iOS 十字绣工具位的在位者集体失能(崩溃/停更/订阅反感/缺平台),而本地零账号恰好是这个品类的天然形态——照片不出设备还是加分项;最关键的未知数是这个爱好圈为移动端工具付费的意愿(免费网页工具惯性强);如果错了,最早在"创建图样后 7 日内进入绣制模式的转化率"上看出来——只创建不绣,说明我们只是又一个一次性转换器。
- **c3_cubecoach**:我们押 c3 能赢,因为品类痛点(扫描不准、无教学、广告敌对)密集且高量,一个"新手优先 + 检查点求解 + 公平变现"的一体 App 能用信任反超;最关键的未知数是端上相机颜色识别能否稳定显著优于在位者;如果错了,最早在"扫描一次成功率/人工修正次数"上看出来——修正摩擦高,wedge 即塌。

# Anti-convergence

top 2 不是同一套机制换皮:c1 是 creation_tool(在格子上创作图样,编辑器是一等公民,领域 cross-stitch-craft),c3 是 game_skill(求解+训练+计时,技能成长回路,领域 rubiks-cube-training)。核心交互(作画/标记 vs 扫描/演练)、骨架、wedge(在位者维护失能 vs 巨头教学缺位)实质不同。两者都保留,押注选 c1。

## Selection rationale

**选定 c1_stitchgrid(产品名 ThreadGrid)**。获胜的是押注论证而非仅分数:value score 偏向 c1(22 vs 20),red-team 确认而非推翻——c1 的 wedge 建立在在位者"手艺与维护"的结构性失能上(可用评论区证据逐条指认),而 c3 的 wedge 押注"端上 CV 反超 24 万评分巨头"这一不可控变量,且 game_skill 骨架 07-26 刚交付过 Waitwise,批次多样性上 c1 的 creation_tool 是本批次全新骨架。明确取舍:放弃 c3 更大的市场深度(5 vs 4),换取更硬的防守位与更低的执行风险。

- skeleton budget:`log_record_archive` 未选(主动抵抗红海拉力);creation_tool 在本批次/近期窗口为零占用,合规。
- domain_cluster budget:`cross-stitch-craft` 在近期历史与当前批次 ledger 均无占用,合规。
- product-depth floor:c1 天然支撑 4 个 task-distinct 主 tab(Charts / Create / Stitch / Threads)+ 编辑器与导出两个深工作区,非单薄单面。
- memory check:无同 pair 冲突;无 novelty 调整。
- proceed_narrow_wedge 立场:wedge_vs_top_n(带 trackId)将落入 `build/product.md` §市场供给与立场 与 `build/non-goals.md`。
