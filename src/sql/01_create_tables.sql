DROP TABLE IF EXISTS VT260701BC766E__STAGING.group_log;

CREATE TABLE VT260701BC766E__STAGING.group_log (
    group_id INT NOT NULL,
    user_id INT NOT NULL,
    user_id_from INT,
    event VARCHAR(10) NOT NULL,
    datetime TIMESTAMP NOT NULL
)
ORDER BY group_id
SEGMENTED BY HASH(user_id) ALL NODES
KSAFE 1;

DROP TABLE IF EXISTS VT260701BC766E__DWH.l_user_group_activity;

CREATE TABLE VT260701BC766E__DWH.l_user_group_activity (
    hk_l_user_group_activity INT PRIMARY KEY,
    hk_user_id INT NOT NULL,
    hk_group_id INT NOT NULL,
    load_dt TIMESTAMP NOT NULL,
    load_src VARCHAR(20) NOT NULL
)
ORDER BY hk_user_id
SEGMENTED BY hk_l_user_group_activity ALL NODES
PARTITION BY load_dt::DATE
KSAFE 1;

DROP TABLE IF EXISTS VT260701BC766E__DWH.s_auth_history;

CREATE TABLE VT260701BC766E__DWH.s_auth_history (
    hk_l_user_group_activity INT NOT NULL,
    user_id_from INT,
    event VARCHAR(10) NOT NULL,
    event_dt TIMESTAMP NOT NULL,
    load_dt TIMESTAMP NOT NULL,
    load_src VARCHAR(20) NOT NULL
)
ORDER BY load_dt
SEGMENTED BY hk_l_user_group_activity ALL NODES
PARTITION BY event_dt::DATE
KSAFE 1;