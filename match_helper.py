import numpy as np
import pandas as pd
import datetime

# ## Google Analytics API v4
# from apiclient.discovery import build
# import httplib2
# from oauth2client import client
# from oauth2client import file
# from oauth2client import tools

## PostgreSQL DB
import psycopg2
import pandas.io.sql as psql

## Parse JSON & get request
from collections import OrderedDict
import argparse
import json
import requests
import getpass

def get_dbaccess():
    """
    Returns:
        - DB_ACCESS: [host, user, pass]
    """
    ACCESS_Path = '/Users/glen/Desktop/SQL external python/'
    print(ACCESS_Path)
    try:
        DB_ACCESS_JSON = json.load(open(ACCESS_Path + 'foursource-rds_replica.json'))
    except OSError:
        raise OSError('IO Error: DB access credential file not found')

    # Database access credentials
    HOST = DB_ACCESS_JSON['hostname']
    USER = DB_ACCESS_JSON['username']
    PASS = DB_ACCESS_JSON['password']
    DB_ACCESS = [HOST, USER, PASS]
    return DB_ACCESS

def execute_query(sql, dbaccess):
    """
    This function takes in a PostgreSQL query and executes it based on the db connection defined.
    If the execution is failed, it will roll back the changes and close the open session.
    """
    try:
        conn = psycopg2.connect(dbname=dbaccess[3], user=dbaccess[1], host=dbaccess[0], password=dbaccess[2])
    except:
        print("UNABLE TO CONNECT TO DATABASE!")

    db = conn.cursor()
    try:
        db.execute(sql)
        conn.commit()
        print ('DB EXECUTION COMMITTED')
    except:
        conn.rollback()
        print ('ERROR SQL EXECUTION! ROLLEDBACK')

    conn.close()


def query_retrieval(sql, dbaccess):
    """
    This function takes in a sql query and extracts data from defined database connection.
    Args:
        - sql
        - dbaccess = [host, user, password, db_name]
    Returns:
        - df: dataframe of extracted info based on sql.
    """
    try:
        conn = psycopg2.connect(dbname=dbaccess[3], user=dbaccess[1], host=dbaccess[0], password=dbaccess[2])
    except:
        print ("UNABLE TO CONNECT TO DATABASE!")
    df = psql.read_sql(sql, conn)
    return df
