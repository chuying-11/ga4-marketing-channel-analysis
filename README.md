# GA4 行銷渠道成效分析（GA4 Marketing Channel Performance Analysis）
> 免費流量貢獻近 7 成使用者，付費廣告未展現較高的轉換效率

以 Google Analytics 4（GA4）公開電商資料集為基礎，透過 BigQuery SQL 分析不同流量渠道的獲客成效與使用者價值，涵蓋 Session 層級與 User 層級分析，並以 Tableau 製作互動式儀表板呈現分析結果。

## Tableau Dashboard
![Dashboard Preview](https://github.com/user-attachments/assets/4a3cff25-8c7f-4271-8842-b4775bd956b6)

[View Interactive Dashboard](https://public.tableau.com/views/GA4MarketingChannelAnalysis/ChannelPerformanceDashboard)

## 商業問題
企業在評估行銷渠道時，不僅需要了解流量規模，也需要判斷不同渠道帶來的使用者品質與商業價值。

本專案透過 Session 與 User 層級分析，回答以下問題：

- 哪些渠道帶來最多網站流量？
- 哪些渠道具有較高轉換效率？
- 哪些渠道帶來較高價值的使用者？
- 免費流量與付費流量是否存在成效差異？

## 資料來源
- **Dataset**：Google Analytics 4 Sample Ecommerce Dataset
- **Platform**：Google BigQuery Public Dataset
- **Analysis Period**：2020/11 – 2021/01
- **Raw Data Size**：約 430 萬筆 Event 資料

## 分析設計
本專案以三層資料結構進行分析：
```text
Event（事件）
 ↓
Session（工作階段）
 ↓
User（使用者）
```
### Session-Level Channel Performance
以工作階段（Session）為分析單位，評估不同渠道帶來的即時轉換效率。

**分析指標：**
- Sessions
- Converted Sessions
- Session Conversion Rate
### First-Touch Channel User Value
以使用者（User）為分析單位，採用 First-Touch Attribution 評估不同渠道帶來的使用者價值。

**選擇 First-Touch Attribution 的原因：**
- 聚焦分析渠道獲客能力，而非最後促成轉換的渠道。
- 避免回訪型渠道（如 Direct）在轉換歸因中被過度放大。
- 更適合評估不同渠道帶來的新使用者價值。
  
**分析指標：**
- Users
- Buyers
- User Conversion Rate
- Orders
- Revenue
- Average Order Value (AOV)

### Channel Classification
原始 GA4 traffic source 包含多種特殊值與來源格式，因此分析前先進行渠道標準化：
- Self-referral：判定為 Direct，避免站內跳轉造成誤歸因。
- `(direct)`：歸類為 Direct。
- `(data deleted)`：保留為 Unknown，避免與其他渠道混合。
- `cpc`：歸類為 Paid Search。
- `organic`：歸類為 Organic Search。
- 其他來源：歸類為 Other。

## 主要發現
- **Organic Search 為主要流量來源**，帶來最多使用者(38%)，但使用者轉換率(1.53%)僅與整體平均相當；單看流量排名會高估其貢獻。
- **Paid Search 未展現較高的轉換效率**(1.53%)，與免費的 Organic Search 持平，但其 AOV(68.9)為可識別渠道中最高，顯示其帶來的使用者可能具有較高消費價值，但目前規模仍有限。
- **Unknown 渠道具有最高轉換率**(7.23%)，但來源資訊因隱私限制缺失，且使用者規模較小，因此不宜直接視為行銷渠道優勢，分析時應獨立呈現。

## 資料限制
- 資料期間限制：分析窗口僅涵蓋 2020/11–2021/01，使用者真實首次接觸可能早於資料期間，因此 First-Touch Attribution 為近似結果。
- 使用者識別限制：`user_pseudo_id` 為裝置層級識別，跨裝置或清除 Cookie 可能造成使用者重複計算。
- 成本資料缺失：資料未包含廣告花費，因此無法評估付費渠道的實際投資報酬率（ROI）。

## 使用技術
- **SQL**：Google BigQuery Standard SQL
- **Data Analysis**：Session Analysis、First-Touch Attribution、Channel Performance Analysis
- **SQL Techniques**：CTE、Window Functions、UNNEST、JOIN、CASE WHEN、Aggregation
- **Dashboard**：Tableau Public
- **Data Source**：GA4 Sample Ecommerce Dataset（Google BigQuery Public Dataset）

## 專案結構
```text
ga4-marketing-channel-analysis/
├── sql/
│   ├── 01_session_channel_performance.sql       # Session 層級渠道成效分析
│   └── 02_first_touch_user_value.sql            # First-Touch 使用者價值分析
├── data/
│   ├── 01_session_channel_performance.csv       # Session 層級分析結果
│   └── 02_first_touch_user_value.csv            # User 層級分析結果
├── tableau/
│   └── ga4_channel_performance_dashboard.twbx   # Tableau Dashboard
└── README.md
```

