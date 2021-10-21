from datetime import datetime, timedelta
import os
from airflow import DAG
from airflow import models
from airflow.hooks.postgres_hook import PostgresHook
from airflow.operators.python_operator import PythonOperator
from airflow.operators.dummy_operator import DummyOperator
from utils.db import get_db_url
import time
from os import listdir
from os.path import isfile, join

DAG_ID = os.path.basename(__file__).replace('.pyc', '').replace('.py', '')

WORKFLOW_DEFAULT_ARGS = {
    'owner': 'vandriichuk',
    'start_date': datetime(2021, 10, 20),
    'depends_on_past': False,
    'retries': 3,
    'retry_delay': 300,
    'email_on_retry': False
}

POSTGRES_CONN_ID = 'test_postgres'

#############################################################################
# Extract / Transform
#############################################################################

def load_from_db_and_save_to_file():

    table_names_list = ['aisles', 'clients', 'departments', 'orders', 'products']

    for table_name in table_names_list:

        full_file_path = os.getcwd() + '/upload-data/' + table_name  + '.csv'
        print(full_file_path)

        sql = f"COPY {table_name} TO '{full_file_path}' DELIMITER ',' CSV HEADER;"

        pg_conn = PostgresHook(postgres_conn_id=POSTGRES_CONN_ID).get_conn()
        cursor = pg_conn.cursor()
        cursor.execute(sql)
        pg_conn.commit()
        pg_conn.close()


with DAG(dag_id=DAG_ID,
         default_args=WORKFLOW_DEFAULT_ARGS,
         description='Upload data from DB to file',
         schedule_interval="@once",
         catchup=False
         ) as dag:

    start_operator = DummyOperator(task_id='Begin_execution', dag=dag,)

    load_from_db_and_save_to_file = PythonOperator(
        task_id="load_from_db_and_save_to_file",
        python_callable=load_from_db_and_save_to_file,
        op_kwargs={},
        dag=dag,
        )

    end_operator = DummyOperator(task_id='Stop_execution', dag=dag,)

    # DAG dependencies
    start_operator >> load_from_db_and_save_to_file >> end_operator
