import pandas as pd
import math
import match_helper as helper

# reload(helper)
dbaccess = helper.get_dbaccess()
buyer_access = dbaccess + ['buyer']
manufacturer_access = dbaccess + ['manufacturer']
shared_access = dbaccess + ['shared']
crm_access = dbaccess + ['crm']

reload(helper)
buyer_sql = """
SELECT
          c.id_company
        , c.name AS company_name
        , country.name AS company_country
        , c.city AS company_city
        , CASE WHEN c.fk_company_status = 1 THEN 'Active' ELSE 'Inactive' END AS company_status
        , c.created_at AS company_created_at
        , to_char(c.created_at::TIMESTAMP WITH TIME ZONE, 'yyyy"M"mm') AS cohort
        , cb.id_company_brand
        , cb.name AS brand_name
        , CASE WHEN cb.fk_company_brand_status = 1 THEN 'Active' ELSE 'Inactive' END AS brand_status
        , cbpo.samples
        , cbpo.out_of_stock
        , cbpo.special_order
        , cbpo.standard_order
        , cbpos.min_qty
        , cbpos.avg_qty
        , cbpos.max_qty
FROM company AS c
LEFT JOIN country ON country.id_country = c.fk_country
LEFT JOIN company_brand AS cb ON cb.fk_company = c.id_company
LEFT JOIN company_brand_po AS cbpo ON cbpo.fk_company_brand = cb.id_company_brand
LEFT JOIN company_brand_po_size AS cbpos ON cbpos.fk_company_brand = cb.id_company_brand
ORDER BY c.id_company, cb.id_company_brand;
"""
b_df = helper.query_retrieval(buyer_sql, buyer_access)
