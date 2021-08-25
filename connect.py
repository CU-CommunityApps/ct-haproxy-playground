#
# Make a single connection to MySQL and reuse/test it forever.
#
import os
import time
import pymysql.cursors

print('Waiting...', flush=True)
time.sleep(15)
print('Connecting to MySQL...', flush=True)

# Connect to the database
host = os.getenv('DB_HOST')
connection = pymysql.connect(host=host,
                             user='root',
                             password='example',
                             database='sys',
                             charset='utf8mb4',
                             port=8080,
                             cursorclass=pymysql.cursors.DictCursor)
sql = "SELECT now() as NOW"
with connection.cursor() as cursor:
  while True:
    # Read a single record
    cursor.execute(sql)
    result = cursor.fetchone()
    print(result['NOW'], host, flush=True)
    time.sleep(5)
