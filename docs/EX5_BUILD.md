# 生成 EX5 文件

`MQL5/Experts/K1_StopLossPoints.mq5` 是 MT5 EA 源码。EX5 是 MetaTrader 5/MetaEditor 生成的编译后二进制文件，不能用普通 Node/Python 工具可靠生成。

## 编译步骤

1. 打开 MetaTrader 5。
2. 点击 **文件 → 打开数据文件夹**。
3. 把 `MQL5/Experts/K1_StopLossPoints.mq5` 复制到数据文件夹下的 `MQL5/Experts/`。
4. 打开 MetaEditor。
5. 在导航器里打开 `K1_StopLossPoints.mq5`。
6. 点击 **Compile / 编译**。
7. 编译成功后，同目录会生成 `K1_StopLossPoints.ex5`。

## 功能范围

- 保留截图中的输入参数和默认值。
- 支持 `buy` / `sell` 图表按钮手动开仓。
- 按手数字符串选择下一单手数。
- 按逆势间距加仓。
- 支持单边点数/金额止盈止损。
- 支持对冲单量达到阈值后的整体盈利平仓。
- 在图表上绘制类似截图的订单水平线。

实盘前请先在模拟账户和策略测试器中确认交易规则、点值、最小手数、滑点和黄金品种名称是否符合你的券商环境。
