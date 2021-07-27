#
# Make a single connection to MySQL and reuse/test it forever.
#
import time
import pymysql.cursors

print('Connecting to MySQL...', flush=True)

# Connect to the database
connection = pymysql.connect(host='haproxy',
                             user='root',
                             password='example',
                             database='sys',
                             charset='utf8mb4',
                             port=9001,
                             cursorclass=pymysql.cursors.DictCursor)
sql = "SELECT now() as NOW"
with connection.cursor() as cursor:
  while True:
    # Read a single record
    cursor.execute(sql)
    result = cursor.fetchone()
    print(result['NOW'], flush=True)
    time.sleep(5)
