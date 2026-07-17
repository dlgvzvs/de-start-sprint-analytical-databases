with user_group_log as (
    select
        luga.hk_group_id,
        COUNT(DISTINCT luga.hk_user_id) as cnt_added_users
    from VT260701BC766E__DWH.l_user_group_activity luga
    where luga.hk_l_user_group_activity in (
        select distinct hk_l_user_group_activity 
        from VT260701BC766E__DWH.s_auth_history 
        where event = 'add'
    )
    group by luga.hk_group_id
),
user_group_messages as (
    select
        luga.hk_group_id,
        COUNT(DISTINCT lum.hk_user_id) AS cnt_users_in_group_with_messages
    FROM VT260701BC766E__DWH.l_user_group_activity luga
    JOIN VT260701BC766E__DWH.l_groups_dialogs lgd 
        ON luga.hk_group_id = lgd.hk_group_id
    JOIN VT260701BC766E__DWH.l_user_message lum 
        ON lgd.hk_message_id = lum.hk_message_id
    GROUP BY luga.hk_group_id
)
select 
    ugl.hk_group_id,
    ugl.cnt_added_users,
    ugm.cnt_users_in_group_with_messages
from user_group_log ugl
left join user_group_messages ugm ON ugl.hk_group_id = ugm.hk_group_id
order by ugm.cnt_users_in_group_with_messages / ugl.cnt_added_users desc
limit 10;

commit;