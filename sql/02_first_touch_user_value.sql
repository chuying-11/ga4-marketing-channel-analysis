-- ============================================================
-- 02. First-Touch Channel User Value
-- ============================================================
-- Business Question:
-- 哪些獲客渠道帶來最高價值的使用者？
--
-- Data Source:
--   GA4 Sample Ecommerce Dataset
--
-- Grain:
--   User (user_pseudo_id)
--
-- Attribution:
--   First Touch
--   每位使用者以首次互動渠道作為歸因
--
-- User Metrics:
--   Users
--   Buyers
--   User Conversion Rate
--   Orders
--   Revenue
--   Average Order Value (AOV)
--
-- Limitations:
-- • Dataset covers only a 3-month period.
-- • user_pseudo_id is device-based.
-- • Advertising cost is unavailable, therefore ROI cannot be calculated.
--
-- Validation:
--   Total Users by Channel = COUNT(DISTINCT user_pseudo_id)
-- ============================================================
WITH events_base AS (
  SELECT
    user_pseudo_id,
    event_timestamp,
    event_name,
    ecommerce.purchase_revenue_in_usd AS revenue,
    CASE
      WHEN traffic_source.source = 'shop.googlemerchandisestore.com'
           AND traffic_source.medium = 'referral' THEN 'Direct'
      WHEN traffic_source.source = '(data deleted)' THEN 'Unknown'
      WHEN traffic_source.source = '(direct)' THEN 'Direct'
      WHEN traffic_source.medium = 'cpc' THEN 'Paid Search'
      WHEN traffic_source.medium = 'organic' THEN 'Organic Search'
      ELSE 'Other'
    END AS channel
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
),

first_touch AS (
  SELECT user_pseudo_id, channel AS ft_channel
  FROM (
    SELECT
      user_pseudo_id, channel,
      ROW_NUMBER() OVER (
        PARTITION BY user_pseudo_id ORDER BY event_timestamp
      ) AS rn
    FROM events_base
  )
  WHERE rn = 1
),

user_value AS (
  SELECT
    user_pseudo_id,
    COUNTIF(event_name = 'purchase') AS orders,
    SUM(IF(event_name = 'purchase', revenue, 0)) AS revenue
  FROM events_base
  GROUP BY user_pseudo_id
)

SELECT
  ft.ft_channel AS channel,
  COUNT(*) AS users,
  COUNTIF(uv.orders > 0) AS buyers,
  ROUND(COUNTIF(uv.orders > 0) / COUNT(*) * 100, 2) AS user_cvr_pct,
  SUM(uv.orders) AS orders,
  ROUND(SUM(uv.revenue), 0) AS revenue_usd,
  ROUND(SUM(uv.revenue) / NULLIF(SUM(uv.orders), 0), 1) AS aov_usd
FROM first_touch ft
JOIN user_value uv USING (user_pseudo_id)
GROUP BY channel
ORDER BY revenue_usd DESC