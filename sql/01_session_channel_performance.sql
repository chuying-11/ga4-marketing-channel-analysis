-- ============================================================
-- 01. Session-Level Channel Performance
-- ============================================================
-- Business Question:
-- 哪些渠道帶來最多流量，以及最高轉換率？
--
-- Data Source:
--   GA4 Sample Ecommerce Dataset（2020-11 ~ 2021-01，共 4,295,584 筆事件）
--
-- Grain:Session
--   Session Key = CONCAT(user_pseudo_id, ga_session_id)
--
-- Channel Attribution:
--   每個 Session 以第一筆事件的 traffic_source 作為來源
--
-- Conversion:
--   Session 內至少發生一次 purchase 即視為轉換
--
-- Channel Cleaning:
--   1. Self-referral → Direct
--   2. (data deleted) → Unknown
--   3. (direct) → Direct
--   4. cpc → Paid Search
--   5. organic → Organic Search
--   6. others → Other
--
-- Validation:
--   Total Sessions by Channel = COUNT(DISTINCT session_key)
-- ============================================================
WITH events_with_session AS (
  SELECT
    CONCAT(
      user_pseudo_id, '-',
      (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id')
    ) AS session_key,
    user_pseudo_id,
    event_timestamp,
    event_name,
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

session_flags AS (
  SELECT
    session_key,
    channel,
    ROW_NUMBER() OVER (
      PARTITION BY session_key ORDER BY event_timestamp
    ) AS rn,
    MAX(IF(event_name = 'purchase', 1, 0)) OVER (
      PARTITION BY session_key
    ) AS has_purchase
  FROM events_with_session
)

SELECT
  channel,
  COUNT(*) AS sessions,
  SUM(has_purchase) AS converted_sessions,
  ROUND(AVG(has_purchase) * 100, 2) AS conversion_rate_pct
FROM session_flags
WHERE rn = 1
GROUP BY channel
ORDER BY conversion_rate_pct DESC