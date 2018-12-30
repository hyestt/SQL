/*
Key Tables:
- crm (signup dashboard)
	- lead
	- plan
	- client
	- plan_type
	- lead_status
	- lead_history (log when member date on lead status change)
- buyer
	- company
	- company_brand
- auth
	- user
- logging
	- tracking_profile
	- login_attempt
	- tracking_search
- messaging
	- invite
	- conversation
	- message
	- newsletter (not used any more)
- shares
	- feed (posts or shares)
	- feed_type
	- follow_* 
- uploader
	- (image files are on s3)

*/

--------------------------------------------------------------
----------------Check Number of Photo per Post----------------
----------------------Note the share type---------------------

SELECT
        SUM(tt.image_count)/COUNT(id_feed)
FROM (
        SELECT 
                f.created_by,
                f.id_feed,
                MIN(ft.name) AS FeedType,
                MIN(fs.name) AS FeedStatus,
                CASE WHEN f.fk_entity_type = 2 THEN 'manufacturer' WHEN f.fk_entity_type = 1 THEN 'buyer' ELSE NULL END,
                f.fk_entity,
                f.title,
                f.description,
                f.created_at,
                COUNT(im.id_feed_image) AS image_count
        FROM feed AS f
        LEFT JOIN feed_type AS ft on ft.id_feed_type = f.fk_feed_type
        LEFT JOIN feed_status AS fs on fs.id_feed_status = f.fk_feed_status
        LEFT JOIN feed_image AS im on im.fk_feed = f.id_feed
        WHERE f.fk_feed_status not in (2,3) AND (im.active = true OR im.active is NULL)
        GROUP BY f.id_feed
        HAVING f.created_at > '2017-12-01 00:00:00' AND f.created_at < '2019-12-01 00:00:00'  
        ORDER BY f.created_at, f.id_feed
) AS tt;

--------------------------------------------------------------
-------------------Check Free Capacity Post-------------------
----------------------Note the share type---------------------

SELECT 
        f.id_feed,
        t.name AS feed_type,
        fs.name AS feed_status,
        CASE 
                WHEN f.fk_entity_type = 1 THEN 'Buyer' 
                ELSE 'Manufacturer' 
        END AS entity_type,
        f.fk_entity AS entity_id,
        to_char(f.created_at::timestamp with time zone, 'yyyy"M"mm'::text) AS post_month,
        f.created_at AS post_timestamp,
        f.created_by AS poster_user_hash,
        f.visible_to_all,
        f.visible_to_watchlist,
        f.visible_to_customers,
        f.visible_to_suppliers,
        string_agg(pg1.name, ', ') AS product_types,
        fc.is_available, 
        fc.quantity,
        fc.available_date,
        fc.validity_from,
        fc.validity_to
FROM feed AS f
LEFT JOIN feed_type AS t 
       ON f.fk_feed_type = t.id_feed_type
LEFT JOIN feed_status AS fs 
       ON fs.id_feed_status = f.fk_feed_status       
LEFT JOIN feed_capacity AS fc 
       ON fc.fk_feed = f.id_feed
LEFT JOIN feed_capacity_pg1 AS fcpg1
       ON fcpg1.fk_feed_capacity = fc.id_feed_capacity
LEFT JOIN pg1
       ON pg1.id_pg1 =  fcpg1.fk_pg1      
WHERE f.fk_feed_type = 7
GROUP BY f.id_feed, t.id_feed_type, fs.id_feed_status, fc.id_feed_capacity
ORDER BY f.id_feed
;

--------------------------------------------------------------
---------------------Check Free Stock Post--------------------
----------------------Note the share type---------------------

SELECT 
        f.id_feed,
        t.name AS feed_type,
        fs.name AS feed_status,
        CASE 
                WHEN f.fk_entity_type = 1 THEN 'Buyer' 
                ELSE 'Manufacturer' 
        END AS entity_type,
        f.fk_entity AS entity_id,
        to_char(f.created_at::timestamp with time zone, 'yyyy"M"mm'::text) AS post_month,
        f.created_at AS post_timestamp,
        f.created_by AS poster_user_hash,
        f.visible_to_all,
        f.visible_to_watchlist,
        f.visible_to_customers,
        f.visible_to_suppliers,
        stock.title,
        stock.type AS sub_type,
        stock.quantity,
        stock.width,
        stock.length
FROM feed AS f
LEFT JOIN feed_type AS t 
       ON f.fk_feed_type = t.id_feed_type
LEFT JOIN feed_status AS fs 
       ON fs.id_feed_status = f.fk_feed_status              
LEFT JOIN feed_stock AS stock
       ON stock.fk_feed = f.id_feed
WHERE f.fk_feed_type = 6
ORDER BY f.id_feed
;

--------------------------------------------------------------
---------------------Check RFQ (wdyn) Post--------------------
----------------------Note the share type---------------------

SELECT 
        f.id_feed,
        t.name AS feed_type,
        fs.name AS feed_status,
        CASE 
                WHEN f.fk_entity_type = 1 THEN 'Buyer' 
                ELSE 'Manufacturer' 
        END AS entity_type,
        f.fk_entity AS entity_id,
        to_char(f.created_at::timestamp with time zone, 'yyyy"M"mm'::text) AS post_month,
        f.created_at AS post_timestamp,
        f.created_by AS poster_user_hash,
        f.visible_to_all,
        f.visible_to_watchlist,
        f.visible_to_customers,
        f.visible_to_suppliers,
        string_agg(country.name, ', ') AS RFQ_countries,
        string_agg(region.name, ', ') AS RFQ_regions,
        rfq.product,
        rfq.specifications,
        rfq.quantity,
        rfq.yearly,
        rfq.one_time,
        rfq.price,
        rfq.delivery_date,
        rfq.validity_from,
        rfq.validity_to,
        rfq.help AS need_customer_success_help
FROM feed AS f
LEFT JOIN feed_type AS t 
       ON f.fk_feed_type = t.id_feed_type
LEFT JOIN feed_status AS fs 
       ON fs.id_feed_status = f.fk_feed_status 
LEFT JOIN feed_wdyn_assoc AS assoc
       ON assoc.fk_feed = f.id_feed                    
LEFT JOIN feed_wdyn AS rfq
       ON rfq.id_feed_wdyn = assoc.fk_feed_wdyn
LEFT JOIN feed_wdyn_country AS rfq_country
       ON rfq_country.fk_feed_wdyn = rfq.id_feed_wdyn
LEFT JOIN country 
       ON country.id_country = rfq_country.fk_country   
LEFT JOIN region  
       ON region.id_region = rfq_country.fk_region              
WHERE f.fk_feed_type = 4
GROUP BY f.id_feed, t.id_feed_type, fs.id_feed_status, assoc.id_feed_wdyn_assoc, rfq.id_feed_wdyn
ORDER BY f.id_feed
;

--------------------------------------------------------------
--------------Check Buyers & Brands--------------------

SELECT
        c.id_company,
        c.name AS company_name,
        cb.id_company_brand AS id_brand,
        cb.name AS brand_name,
        CASE
                WHEN c.fk_company_status = 1 THEN 'Active'
                ELSE 'Deactivated'
        END AS company_status,
        CASE
                WHEN cb.fk_company_brand_status = 1 THEN 'Active'
                ELSE 'Deactivated'
        END AS brand_status,    
        country.name AS country,    
        c.created_at AS member_timestamp,
        to_char(c.created_at::timestamp with time zone, 'yyyy"M"mm'::text) AS member_cohort
FROM company AS c
LEFT JOIN company_brand AS cb
       ON cb.fk_company = c.id_company
LEFT JOIN country 
       ON country.id_country = c.fk_country     
ORDER BY c.id_company, cb.id_company_brand        
; 

--------------------------------------------------------------
--------------Check Obnoarded Buyer Entity--------------------
------------------------per month-----------------------------

SELECT 
      t.id_company AS id_entity
    , t.company_name AS entity_name
    , t.fk_company_status AS fk_entity_status
    , t.status_name
    , t.fk_country
    , t.country_name
    , t.created_at AS member_date
    , to_char(t.created_at::timestamp with time zone, 'iyyy"W"IW'::text) AS member_year_week    
    , to_char(t.created_at::timestamp with time zone, 'yyyy"M"mm'::text) AS member_year_month
    , min(t.filled_mandatory_reached_at) AS ob_time
    , to_char(min(t.filled_mandatory_reached_at)::timestamp with time zone, 'iyyy"W"IW'::text) AS ob_year_week
    , to_char(min(t.filled_mandatory_reached_at)::timestamp with time zone, 'yyyy"M"mm'::text) AS ob_year_month        
    , count(t.id_company_brand) AS count_brands
    , (CASE WHEN min(t.filled_mandatory_reached_at) IS NULL THEN 0 ELSE 1 END) AS been_onboarded_bool
FROM (
    SELECT 
          c.id_company
        , c.name AS company_name 
        , c.fk_company_status  
        , s.name AS status_name 
        , c.fk_country 
        , ct.name AS country_name 
        , c.created_at  
        , c.updated_at  
        , cb.id_company_brand 
        , cb.name AS brand_name 
        , pf.filled_mandatory_reached_at 
        , pf.filled_mandatory_reached 
    FROM company AS c 
    LEFT JOIN company_status AS s ON s.id_company_status = c.fk_company_status 
    LEFT JOIN company_brand AS cb ON cb.fk_company = c.id_company 
    LEFT JOIN profile_fill AS pf ON pf.fk_company_brand = cb.id_company_brand 
    LEFT JOIN country AS ct ON ct.id_country = c.fk_country
    WHERE c.fk_company_status = 1  -- Only filter for active entity
) AS t
GROUP BY 1, 2, 3, 4, 5, 6, 7
HAVING t.
ORDER BY t.id_company;

-- CHECK BUYER ONBOARDING YEAR, MONTH, WEEK

SELECT
	  id_company
	, id_company_brand
	, index
	, filled_mandatory_reached_at AS br_filled_mandatory_reached_at
	, to_char(filled_mandatory_reached_at::timestamp with time zone, 'iyyy"W"IW'::text) AS br_fo_year_week
	, to_char(filled_mandatory_reached_at::timestamp with time zone, 'yyyy"M"mm'::text) AS br_fo_year_month
	, MIN(co_filled_mandatory_reached_at) AS co_filled_mandatory_reached_at
	, MIN(co_fo_year_week) AS co_fo_year_week
	, MIN(co_fo_year_month) AS co_fo_year_month
FROM company
LEFT JOIN (
        SELECT 
                  id_company_brand 
                , fk_company
                , row_number() over (PARTITION BY fk_company ORDER BY id_company_brand) AS index
        FROM company_brand
) AS br_base ON br_base.fk_company = id_company
LEFT JOIN (	
        SELECT
                  fk_company_brand
                , fk_company  
                , filled_mandatory_reached_at as co_filled_mandatory_reached_at
		, to_char(filled_mandatory_reached_at::timestamp with time zone, 'iyyy"W"IW'::text) as co_fo_year_week
		, to_char(filled_mandatory_reached_at::timestamp with time zone, 'yyyy"M"mm'::text) as co_fo_year_month
        FROM profile_fill
	LEFT JOIN company_brand on fk_company_brand = id_company_brand
) AS co_base ON id_company = co_base.fk_company
LEFT JOIN profile_fill a ON id_company_brand = a.fk_company_brand
GROUP BY 1,2,3,4,5
-- HAVING id_company = 93
ORDER BY 1,2;

--------------------------------------------------------------
------------Check Obnoarded Manufacturer Entity---------------
------------------------per month-----------------------------

SELECT 
      m.id_manufacturer AS id_entity
    , m.name AS entity_name
    , m.fk_manufacturer_status AS fk_entity_status
    , s.name AS status_name
    , m.fk_country
    , ct.name AS country_name
    , m.created_at AS member_date
    , to_char(m.created_at::timestamp with time zone, 'iyyy"W"IW'::text) AS member_year_week
    , to_char(m.created_at::timestamp with time zone, 'yyyy"M"mm'::text) AS member_year_month
    , pf.filled_mandatory_reached_at AS ob_time
    , to_char(pf.filled_mandatory_reached_at::timestamp with time zone, 'iyyy"W"IW'::text) AS ob_year_week
    , to_char(pf.filled_mandatory_reached_at::timestamp with time zone, 'yyyy"M"mm'::text) AS ob_year_month
    , (CASE WHEN pf.filled_mandatory_reached_at IS NULL THEN 0 ELSE 1 END) AS been_onboarded_bool
FROM manufacturer AS m 
LEFT JOIN manufacturer_status AS s ON s.id_manufacturer_status = m.fk_manufacturer_status 
LEFT JOIN profile_fill AS pf ON pf.fk_manufacturer = m.id_manufacturer
LEFT JOIN country AS ct ON ct.id_country = m.fk_country
WHERE m.fk_manufacturer_status = 1   -- only get active entity
  AND pf.filled_mandatory_reached_at < '2017-10-01 00:00:00'
  AND pf.filled_mandatory_reached_at > '2017-09-01 00:00:00'
ORDER BY 1;

--------------------------------------------------------------
---------Check count of acceptance in lead history------------
--------------------------------------------------------------

SELECT 
      h.id_lead
    , h.fk_client
    , h.fk_lead_status
    , count(h.id_lead) 
FROM lead_history AS h 
WHERE h.fk_lead_status = 5 
GROUP BY h.id_lead, h.fk_client, h.fk_lead_status
HAVING count(h.id_lead) > 1
ORDER BY h.id_lead;

--------------------------------------------------------------
---------------Check search params & results------------------
--------------------------------------------------------------

SELECT 
          id_tracking_search
        , user_hashed_id
        , CASE 
                WHEN s.fk_entity_type = 1 THEN 'buyer' 
                WHEN s.fk_entity_type = 2 THEN 'manufacturer' 
                ELSE 'empty' 
        END AS entity_type 
        , query_params
        , json_each(query_params) as key_val_pair
        , results
        , json_array_length(query_params) AS nr_query_params 
        , json_array_length(results) AS nr_result 
        , created_at as search_date
        , to_char(created_at::timestamp with time zone, 'iyyy"W"IW'::text) as search_year_week
        , to_char(created_at::timestamp with time zone, 'yyyy"M"mm'::text) as search_year_month
FROM public.tracking_search
WHERE json_array_length(results) IS NOT NULL;

--------------------------------------------------------------
------------------------Followings----------------------------
---------Watchlist, Supplier List, Customer List--------------

-- uid_follow: [manufacturer_watchlist/brand_watchlist/supplier/customer]-[1/2 (follower fk entity type)]-[id_folllow_relation]
-- follow_type: [manufacturer_watchlist/brand_watchlist/supplier/customer]
-- id_follow_relation: id of original table
-- follower_entity_type: string [Manufacturer/Brand]
-- follower_fk_entity_type: 1 for brand, 2 for manufacturer
-- follower_id
-- followed_entity_type: string [Manufacturer/Brand]
-- followed_fk_entity_type: 1 for brand, 2 for manufacturer
-- followed_id
-- active
-- follow_timestamp
-- follow_year_week
-- follow_year_month
-- follow_year
-- follow_user_hash

SELECT    
          'manufacturer_watchlist-2-' || id_follow_company_brand AS uid_follow
        , 'manufacturer_watchlist' AS follow_type  
        , id_follow_company_brand AS id_follow_relation
        , 'Manufacturer' AS follower_entity_type
        , 2 AS follower_fk_entity_type
	, fk_manufacturer AS follower_id
	, 'Brand' AS followed_entity_type
	, 1 AS followed_fk_entity_type
	, fk_company_brand AS followed_id
	, active
	, created_at AS follow_timestamp
	, to_char(created_at::timestamp with time zone, 'iyyy"W"IW'::text) AS follow_year_week
	, to_char(created_at::timestamp with time zone, 'yyyy"M"mm'::text) AS follow_year_month
	, to_char(created_at::timestamp with time zone, 'yyyy'::text) AS follow_year
	, user_hashed_id AS follow_user_hash
FROM public.follow_company_brand

UNION

SELECT    
          'brand_watchlist-2-' || id_follow_manufacturer AS uid_follow
        , 'brand_watchlist' AS follow_type  
        , id_follow_manufacturer AS id_follow_relation
        , 'Brand' AS follower_entity_type
        , 1 AS follower_fk_entity_type
	, fk_company_brand AS follower_id
	, 'Manufacturer' AS followed_entity_type
	, 2 AS followed_fk_entity_type
	, fk_manufacturer AS followed_id
	, active
	, created_at AS follow_timestamp
	, to_char(created_at::timestamp with time zone, 'iyyy"W"IW'::text) AS follow_year_week
	, to_char(created_at::timestamp with time zone, 'yyyy"M"mm'::text) AS follow_year_month
	, to_char(created_at::timestamp with time zone, 'yyyy'::text) AS follow_year
	, user_hashed_id AS follow_user_hash
FROM public.follow_manufacturer

UNION 

SELECT
          'supplier-1-' || id_add_supplier AS uid_follow
        , 'supplier' AS follow_type  
        , id_add_supplier AS id_follow_relation
        , 'Brand' AS follower_entity_type
        , 1 AS follower_fk_entity_type
	, ext_id_company_brand AS follower_id
	, 'Manufacturer' AS followed_entity_type
	, 2 AS followed_fk_entity_type
	, ext_id_manufacturer AS followed_id
	, active
	, created_at AS follow_timestamp
	, to_char(created_at::timestamp with time zone, 'iyyy"W"IW'::text) AS follow_year_week
	, to_char(created_at::timestamp with time zone, 'yyyy"M"mm'::text) AS follow_year_month
	, to_char(created_at::timestamp with time zone, 'yyyy'::text) AS follow_year
	, NULL AS follow_user_hash
FROM public.add_supplier

UNION 

SELECT
          'customer-2-' || id_add_customer AS uid_follow
        , 'customer' AS follow_type  
        , id_add_customer AS id_follow_relation
        , 'Manufacturer' AS follower_entity_type
        , 2 AS follower_fk_entity_type
	, ext_id_manufacturer AS follower_id
	, 'Brand' AS followed_entity_type
	, 1 AS followed_fk_entity_type
	, ext_id_company_brand AS followed_id
	, active
	, created_at AS follow_timestamp
	, to_char(created_at::timestamp with time zone, 'iyyy"W"IW'::text) AS follow_year_week
	, to_char(created_at::timestamp with time zone, 'yyyy"M"mm'::text) AS follow_year_month
	, to_char(created_at::timestamp with time zone, 'yyyy'::text) AS follow_year
	, NULL AS follow_user_hash
FROM public.add_customer
ORDER BY follow_timestamp, id_follow_relation;

--------------------------------------------------------------
----------------------Profile Track---------------------------
----------Map profile tab view to profile views---------------

SELECT
          base.*
        , CASE WHEN base.end_current_interval IS NULL OR base.end_current_interval < base.viewed_date
               THEN 'get' 
               ELSE 'refresh'
          END AS token

FROM (
        SELECT    
                  id_tracking_profile AS id_tracking_profile_tab
                , viewer_hashed_id
                , viewed_entity_id
                , fk_tracking_section
                , et.id_entity_type AS viewed_id_entity_type
                , et.name AS viewed_entity_type
                , created_at AS viewed_datetime
                , created_at::date AS viewed_date
                , to_char(created_at::timestamp with time zone, 'iyyy"W"IW'::text) AS viewed_year_week
                , to_char(created_at::timestamp with time zone, 'yyyy"M"mm'::text) AS viewed_year_month
                , to_char(created_at::timestamp with time zone, 'yyyy'::text) AS viewed_year
                , ROW_NUMBER() OVER (PARTITION BY created_at::date, viewer_hashed_id, viewed_entity_id ORDER BY id_tracking_profile) AS profile_view_index
                , created_at + (30 ||'minutes')::interval AS viewed_end_new_interval
                , lag(id_tracking_profile) 
                       OVER (PARTITION BY created_at::date, viewer_hashed_id, viewed_entity_id ORDER BY id_tracking_profile) AS last_tracking_id_in_partition
                , CASE WHEN lag(created_at::date || viewer_hashed_id || viewed_entity_id) 
                               OVER (PARTITION BY created_at::date, viewer_hashed_id, viewed_entity_id ORDER BY id_tracking_profile) 
                            = created_at::date || viewer_hashed_id || viewed_entity_id 
                       THEN lag(created_at + (30 ||' minutes')::interval) 
                               OVER (PARTITION BY created_at::date, viewer_hashed_id, viewed_entity_id ORDER BY id_tracking_profile)
                       ELSE NULL 
                  END AS end_current_interval
        FROM tracking_profile AS t
        LEFT JOIN tracking_section AS ts ON t.fk_tracking_section = ts.id_tracking_section
        LEFT JOIN entity_type AS et ON et.id_entity_type = ts.fk_entity_type
        ORDER BY created_at::date, viewer_hashed_id, id_tracking_profile
) AS base

