INSERT INTO VT260701BC766E__DWH.l_user_group_activity(hk_l_user_group_activity, hk_user_id, hk_group_id, load_dt, load_src)
SELECT DISTINCT
    hash(hu.user_id, hg.group_id) AS hk_l_user_group_activity,
    hu.hk_user_id,
    hg.hk_group_id,
    NOW() AS load_dt,
    's3' AS load_src
FROM VT260701BC766E__STAGING.group_log AS gl
LEFT JOIN VT260701BC766E__DWH.h_users hu ON gl.user_id = hu.user_id
LEFT JOIN VT260701BC766E__DWH.h_groups hg ON gl.group_id = hg.group_id;

INSERT INTO VT260701BC766E__DWH.s_auth_history(hk_l_user_group_activity, user_id_from, event, event_dt, load_dt, load_src)
SELECT DISTINCT
    luga.hk_l_user_group_activity,
    gl.user_id_from,
    gl.event,
    gl.datetime AS event_dt,
    NOW() AS load_dt,
    'group_log' AS load_src
FROM VT260701BC766E__STAGING.group_log AS gl
LEFT JOIN VT260701BC766E__DWH.h_groups AS hg ON gl.group_id = hg.group_id
LEFT JOIN VT260701BC766E__DWH.h_users AS hu ON gl.user_id = hu.user_id
LEFT JOIN VT260701BC766E__DWH.l_user_group_activity AS luga 
    ON hg.hk_group_id = luga.hk_group_id AND hu.hk_user_id = luga.hk_user_id;