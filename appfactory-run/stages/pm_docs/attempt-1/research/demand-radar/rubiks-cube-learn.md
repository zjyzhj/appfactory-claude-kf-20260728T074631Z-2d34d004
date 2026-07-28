## Demand radar: Rubik's cube solver / learning apps

| pain_query | source | signal_strength | verbatim_quotes | why_existing_fails | candidate_wedge_seed |
|---|---|---|---|---|---|
| solver 拒绝正确输入 | https://itunes.apple.com/us/rss/customerreviews/id=1604603007/sortBy=mostRecent/json | high | "it keeps saying incorrect when it's correct. I looked at the whole Rubiks cube put the colors in and it said incorrect." | 颜色校验苛刻且无错误指引 | 指出具体冲突色块并一键修正 |
| 扫描误读颜色 | 同上 + https://itunes.apple.com/ca/rss/customerreviews/id=1673039373/sortBy=mostRecent/json | high | "It would change my colors mid time" / "the cube in the app is always wrong. Why is the yellow next to the white?" | 扫描/配色识别准确率是已知弱点 | 逐面置信度预览后再求解 |
| 求解结果更乱 | https://itunes.apple.com/gb/rss/customerreviews/id=1505663005/sortBy=mostRecent/json | high | "Went to solve it with instructions and made it even more scrambled. would not use app" | 展示状态与实体魔方之间无校验回路 | 分步检查点("现在你的魔方应该长这样")+ 回退 |
| 缺新手学习路径 | https://itunes.apple.com/us/rss/customerreviews/id=1604603007/sortBy=mostRecent/json | high | "I'm a complete beginner and it doesn't have visual directions... it only tells you the letters RUF" | solver 只抛记号不教学 | 记号入门 → 层先法 → 算法 drills 的结构化课程 |
| 广告/付费墙反感 | https://itunes.apple.com/gb/rss/customerreviews/id=1505663005/sortBy=mostRecent/json | high | "I literally can't find a single Rubik's cube solver app that either I don't pay to get the app in the first place or paying in game transactions" / "you need to watch an add for everything" | 品类变现激进(广告门禁求解) | 干净公平的一次性/消耗制变现作为差异点 |

**Demand summary:** 痛点真实且非常高频——品类评分数十万级,密集一星聚集在(1) 输入/扫描不可靠、(2) 无解后更乱且无恢复路径、(3) 广告/付费墙敌对、(4) 没有真正的新手学习路径。缺口是"新手优先 + 可校验求解 + 结构化课程 + 公平变现"的一体 App;但在位者(ASolver 27.8 万评分、Cube Solver 3D 24.1 万)装机与 ASO 引力极强。
