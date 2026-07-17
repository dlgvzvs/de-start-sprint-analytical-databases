with only_starichki as (
	SELECT 
		hg.hk_group_id -- вроде хеша по группе здесь достаточно
	FROM VT260701BC766E__DWH.h_groups hg -- из справочника групп
	ORDER BY hg.registration_dt ASC -- тут же делаю сортировку по дате регистрации
	LIMIT 10 -- отбираю 10 старичков
),

user_group_log as (
    select
        luga.hk_group_id,
        COUNT(DISTINCT luga.hk_user_id) as cnt_added_users
    from VT260701BC766E__DWH.l_user_group_activity luga
    inner join only_starichki os ON luga.hk_group_id = os.hk_group_id -- сразу оставляем только 10 старичков
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
    inner join only_starichki os ON luga.hk_group_id = os.hk_group_id -- аналогично
    JOIN VT260701BC766E__DWH.l_groups_dialogs lgd 
        ON luga.hk_group_id = lgd.hk_group_id
    JOIN VT260701BC766E__DWH.l_user_message lum 
        ON lgd.hk_message_id = lum.hk_message_id
    GROUP BY luga.hk_group_id
)
select 
    os.hk_group_id, -- надежнеё вывести хэш из таблицы старичков
    coalesce(ugl.cnt_added_users, 0) as cnt_added_users, -- если данных нет, покажем ноль
    coalesce(ugm.cnt_users_in_group_with_messages, 0) as cnt_users_in_group_with_messages,
    coalesce(ugm.cnt_users_in_group_with_messages / ugl.cnt_added_users, 0) as group_conversion
from only_starichki os
left join user_group_log ugl ON os.hk_group_id = ugl.hk_group_id
left join user_group_messages ugm ON os.hk_group_id = ugm.hk_group_id
; -- убрал order by и limit

commit;