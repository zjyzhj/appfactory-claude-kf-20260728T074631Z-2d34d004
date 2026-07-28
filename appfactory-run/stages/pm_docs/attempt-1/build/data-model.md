# ThreadGrid · 数据模型(本地持久化,SwiftData 或等价;全部零账号本地)

## 实体

### Chart(图样)
| 字段 | 类型 | 说明 |
|---|---|---|
| id | UUID | 主键 |
| title | String | 用户命名(en-US 输入) |
| sourcePhotoPath | String? | 应用沙盒内相对路径的源照片副本(可为空=空白起稿) |
| finishedPhotoPath | String? | 成品照相对路径(stitch 完工时拍摄/选取) |
| widthCells / heightCells | Int | 格点尺寸(30–200 区间) |
| maxColors | Int | 生成时色数上限(4–60) |
| cells | Data | 按行优先的 colorIndex 数组(每格 1 byte 索引到 palette) |
| palette | [ChartColor] | 本图样用色(见下,内嵌) |
| status | enum: draft / active / finished | active=在绣 |
| stitchedCellIndices | Set<Int> | 已绣格子索引(进度真相源) |
| createdAt / updatedAt | Date | |

### ChartColor(图样内用色,内嵌于 Chart)
| 字段 | 类型 | 说明 |
|---|---|---|
| colorIndex | Int | 格内索引 |
| dmcCode | String | 如 "310"(映射到 DMCThread) |
| symbol | String | 打印图解用符号(自动分配,如 ▲ ● ◆ ✕) |
| stitchCount | Int | 该色格数(派生存储,编辑器维护) |

### DMCThread(内置色库,bundle 只读数据)
| 字段 | 类型 | 说明 |
|---|---|---|
| dmcCode | String | 主键,如 "310" |
| name | String | en-US 名,如 "Black" |
| hex | String | 显示色 |

### StashEntry(我的绣线)
| 字段 | 类型 | 说明 |
|---|---|---|
| dmcCode | String | 关联 DMCThread |
| skeinsOwned | Int | 拥有绞数 |

### CreditLedger(Export Credits,yanran 消耗制)
| 字段 | 类型 | 说明 |
|---|---|---|
| balance | Int | 当前点数余额 |
| transactions | [CreditTxn] | 内嵌流水 |

### CreditTxn
| 字段 | 类型 | 说明 |
|---|---|---|
| id | UUID | |
| kind | enum: purchase / consume / grant | grant=首启赠送 2 枚 |
| amount | Int | purchase/grant 为正,consume 为负 |
| storekitTransactionId | String? | purchase 时记录(对账) |
| createdAt | Date | |

### ExportRecord(导出历史)
| 字段 | 类型 | 说明 |
|---|---|---|
| id | UUID | |
| chartId | UUID | 关联 Chart |
| kind | enum: image_card / printable_pdf | image_card 免费;printable_pdf 消耗 1 Credit |
| createdAt | Date | |

## 关系

- Chart 1—n ChartColor(内嵌);ChartColor.dmcCode → DMCThread(查表)。
- Chart 1—n ExportRecord;Chart 0—1 active(stitch_session 全局只一个 activeChartId)。
- StashEntry.dmcCode → DMCThread;图样线量清单 = Chart.palette join StashEntry(缺线高亮)。
- CreditLedger 单例;所有 PDF 导出必须 consume 成功才渲染。

## 派生规则

- progress% = stitchedCellIndices.count / (widthCells × heightCells)。
- 编辑格子 → 维护 stitchCount;改色若该格已绣,保留进度(进度按格不按色)。
- 删除 Chart → 级联删除 ExportRecord、stitchedCellIndices、沙盒照片副本(确认弹窗明示)。
