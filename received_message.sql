--The number of manufacturer received message coming from buyer
--The number of buyer who sent the message to manufacturer

-- database: message

WITH message AS (SELECT
                  c.id_conversation AS id_subject
                , c.subject 
                , c.fk_status AS fk_subject_status
                , cs.name AS subject_status
                , c.created_at AS subject_created_at
                , to_char(c.created_at::timestamp WITH TIME ZONE, 'iyyy"W"IW'::text) AS subject_created_year_week
                , to_char(c.created_at::timestamp WITH TIME ZONE, 'yyyy"M"mm'::text) AS subject_created_year_month
                , to_char(c.created_at::timestamp WITH TIME ZONE, 'yyyy'::text) AS subject_created_year
                , c.owner AS subject_owner
                , cp.id_conversation_participant AS id_subject_participant
                , cp.user_hash
                , cp.first_name 
                , cp.last_name
                , CASE WHEN fk_user_type = 1 THEN 'Buyer' WHEN fk_user_type = 2 THEN 'Manufacturer' ELSE 'CRM' END AS user_entity_type
                , cp.entity_id
                , cp.entity_name
                , cps.name AS participant_status
                , cp.is_admin AS is_subject_admin
                , cp.archived AS participant_is_archived
                , cp.is_online AS participant_is_online
                , cp.created_at AS participant_created_at
                , to_char(cp.created_at::timestamp WITH TIME ZONE, 'iyyy"W"IW'::text) AS participant_created_year_week
                , to_char(cp.created_at::timestamp WITH TIME ZONE, 'yyyy"M"mm'::text) AS participant_created_year_month
                , to_char(cp.created_at::timestamp WITH TIME ZONE, 'yyyy'::text) AS participant_created_year
                , m.id_conversation_participant_message AS id_message
                , m.message
                , mt.name AS message_type
                , ms.name AS message_status
                , m.link AS message_link
                , m.updated AS message_is_updated
                , m.created_at AS message_created_at
                , to_char(m.created_at::timestamp WITH TIME ZONE, 'iyyy"W"IW'::text) AS message_created_year_week
                , to_char(m.created_at::timestamp WITH TIME ZONE, 'yyyy"M"mm'::text) AS message_created_year_month
                , to_char(m.created_at::timestamp WITH TIME ZONE, 'yyyy'::text) AS message_created_year
                , m.sent_at AS message_sent_at
        FROM conversation AS c
        LEFT JOIN conversation_status AS cs 
                ON cs.id_conversation_status = c.fk_status
        LEFT JOIN conversation_participant AS cp 
               ON cp.fk_conversation = c.id_conversation
        LEFT JOIN conversation_participant_status AS cps 
               ON cps.id_conversation_participant_status = cp.fk_participant_status
        LEFT JOIN conversation_participant_message AS m 
               ON m.fk_conversation_participant = cp.id_conversation_participant
        LEFT JOIN conversation_participant_message_type AS mt 
               ON mt.id_conversation_participant_message_type = m.fk_conversation_participant_message_type
        LEFT JOIN conversation_participant_message_status AS ms
               ON ms.id_conversation_participant_message_status = m.fk_conversation_participant_message_status
        WHERE mt.name != 'Status'
        ORDER BY c.id_conversation, m.id_conversation_participant_message
)


SELECT   
        t.entity_uid,
        MIN(t.entity_id) AS entity_id,
        COUNT(DISTINCT m3.user_entity_type || '-' || m3.entity_id) AS nr_buyers,
        COUNT(DISTINCT m3.id_message) AS nr_messages_received_from_buyers
FROM (
        SELECT  
                m.id_subject,
                m.entity_id,
                m.user_entity_type,
                m.user_entity_type || '-' || m.entity_id AS entity_uid,
                m.id_message,
                m.message
        FROM message AS m
) AS t
LEFT JOIN message AS m3 ON m3.id_subject = t.id_subject AND m3.user_entity_type = 'Buyer'
WHERE t.user_entity_type = 'Manufacturer'
GROUP BY t.entity_uid
ORDER BY 2;
