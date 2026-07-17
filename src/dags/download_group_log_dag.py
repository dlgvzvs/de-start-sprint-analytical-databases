from airflow import DAG # всё начинается с импортов
from airflow.operators.python import PythonOperator
from airflow.providers.amazon.aws.hooks.s3 import S3Hook
from datetime import datetime, timedelta
import boto3
import vertica_python

default_args = { # для дага необходимы аргументы по умолчанию, их напишем в первую очередь
    'owner': 'dlgvzvs',
    'depends_on_past': False,
    'start_date': datetime(2026, 7, 15),
    'retries': 5,
    'retry_delay': timedelta(minutes=5)
}

dag = DAG ( # непосредственно сам даг
    dag_id = 'load_group_log_from_s3',
    default_args = default_args,
    description = 'Скачиваем файл из S3',
    schedule_interval = '@once',
    catchup = False
)

# скачивает файл не даг, а функция внутри дага, здесь её и пропишу
def download_group_log():
    aws_access_key_id = "YCAJEiyNFq4wiOe_eMCMCXmQP"
    aws_secret_access_key = "YCP1e96y4QI8OmcB4Eaf4q0nMHwhmtvGbDTgBeqS"
    session = boto3.session.Session()
    s3_client = session.client(
        service_name='s3',
        endpoint_url='https://storage.yandexcloud.net',
        aws_access_key_id=aws_access_key_id,
        aws_secret_access_key=aws_secret_access_key,
    )
    s3_client.download_file(
        Bucket='sprint6',
        Key='group_log.csv',
        Filename='/data/group_log.csv'
    )

# шаг 3 - описание функции
def load_to_vertica():
    import pandas as pd
    import vertica_python
    from io import StringIO
    
    # 1. Читаем CSV
    df = pd.read_csv('/data/group_log.csv')
    
    # 2. Заменяем NaN на пустую строку (для COPY)
    df['user_id_from'] = df['user_id_from'].fillna('')
    
    # 3. Сохраняем в буфер без заголовка
    buffer = StringIO()
    df.to_csv(buffer, index=False, header=False)
    buffer.seek(0)
    
    # 4. Подключаемся к Vertica
    conn = vertica_python.connect(
        host='vertica.data-engineer.education-services.ru',
        port=5433,
        user='vt260701bc766e',
        password='19dada60e18c4747a7d3c530f6892125',
        database='dwh'
    )
    cur = conn.cursor()
    
    # 5. COPY из STDIN
    cur.copy("""
        COPY VT260701BC766E__STAGING.group_log 
        (group_id, user_id, user_id_from, event, datetime)
        FROM STDIN 
        DELIMITER ',' 
        NULL AS ''
    """, buffer)
    
    conn.commit()
    conn.close()

# можно сразу вызывать эту функцию
download_task = PythonOperator (
    task_id = 'download_group_log',
    python_callable = download_group_log,
    dag = dag
)

# шаг 3 - вызов функции
upload_task = PythonOperator (
    task_id = 'load_to_vertica',
    python_callable = load_to_vertica,
    dag = dag
)

download_task >> upload_task