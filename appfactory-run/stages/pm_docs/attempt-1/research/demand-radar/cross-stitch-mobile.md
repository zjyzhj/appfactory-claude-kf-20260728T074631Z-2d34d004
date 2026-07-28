## Demand radar: cross-stitch pattern making & progress tracking on mobile

| pain_query | source | signal_strength | verbatim_quotes | why_existing_fails | candidate_wedge_seed |
|---|---|---|---|---|---|
| Markup R-XP symbol detection unreliable | https://itunes.apple.com/us/rss/customerreviews/id=1559524491/sortBy=mostRecent/json | high | "Symbol detection is extremely inconsistent rendering the app as useless. It can't be trusted. Going back to Pattern Keeper." / "When I select the symbol it highlights other symbols with it and leaves off some that is supposed to be highlighted." | 核心跟踪机制(PDF 符号识别)在真实图纸上失败,用户无法信任 tracker | 格子即真相:图样在 App 内是一等数据对象,不依赖 PDF 符号识别 |
| Markup R-XP 停更 + 订阅反感 | 同上 | high | "paying for a subscription with no updates in two years is a joke. PDFs import blurry, the UX is a bit clunky, no real ability to detect fractional stitches" | 收订阅费却不维护(trackId 1559524491 最后更新 2024-04-18);导入模糊 | 本地零账号 + 消耗制付费,无订阅;矢量渲染格子图 |
| Markup R-XP UX 难以上手 | 同上 | med | "I can't figure out simple things like how to delete a project... I have clicked all around for 20 minutes" / "I could've spent those hours actually cross stitching." | 功能堆叠无引导, setup 成本超过价值 | 新手友好的创建向导:照片进、校验后的图样出 |
| Stitchly 导入崩溃 + 尺寸受限 | https://itunes.apple.com/gb/rss/customerreviews/id=1467867656/sortBy=mostRecent/json | med | "when I import a PDF pattern, it just crashes and you can't select anything?" / "all the patterns come out small…wish there was a way to make your actual design bigger." / "free ?! ...only for teeny weeny patterns" | 导入路径崩溃;生成引擎与免费层限制图样尺寸 | 显式的尺寸/色数控制,免费层可用 |
| 照片转图样质量(像素化/色差) | https://crewelghoul.com/blog/photo-to-cross-stitch-converters/ | high | "I put the pic in and it was pixels so I tried to fix it but no it got worse" / (Stitch Fiddle) "it's only accessible in the internet browser... it's not as responsive as an iOs app would be." | 自动取色需要大量手工清理;最好的工具是网页版,移动端体验弱 | 移动端原生照片转图 + DMC 真实线色对照预览 |
| Pattern Keeper 无 iOS 版 | https://itunes.apple.com/search?term=pattern+keeper&entity=software&country=us (无结果) | med | (Markup R-XP 评论) "This is the only app of its kind yet I can't use it" | 最受喜爱的 tracker(Pattern Keeper)仅 Android;iOS 用户觉得被忽视 | iOS 一等公民的图样 + 进度一体工具 |

**Demand summary:** 痛点真实、高频且在 iOS 端未被满足——两个在位 App 的核心回路(导入图纸、跟踪进度)收获密集一星差评,Pattern Keeper 无 iOS 版,照片转图样的质量(颜色、像素化、尺寸上限)是有记录的弱点。可信的创建 + 跟踪一体工具有明确 wedge。
