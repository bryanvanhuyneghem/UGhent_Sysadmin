#!/bin/env python3

from flask import Flask
from flask_mysqldb import MySQL
import os


app = Flask(__name__)
mysql = MySQL(app)

app.config['MYSQL_HOST'] = os.environ["MYSQL_HOST"]
app.config['MYSQL_USER'] = os.environ["MYSQL_USER"]
app.config['MYSQL_PASSWORD'] = os.environ["MYSQL_PASSWORD"]

print("MYSQL_HOST: ", os.environ["MYSQL_HOST"])
print("MYSQL_USER: ", os.environ["MYSQL_USER"])
print("MYSQL_PASSWORD: ", os.environ["MYSQL_PASSWORD"])

@app.route('/')
def users():
    cur = mysql.connection.cursor()
    cur.execute('''SELECT user, host FROM mysql.user''')
    rv = cur.fetchall()
    return str(rv)

if __name__ == '__main__':
    app.run(debug=True, host="0.0.0.0")
