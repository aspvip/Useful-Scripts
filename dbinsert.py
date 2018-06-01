#!/usr/bin/python
# -*- coding: utf-8 -*-
#Server Connection to MySQL:

import MySQLdb
conn = MySQLdb.connect(host= "localhost",
                  user="root",
                  passwd="T@d@k@n3v3r8l33p8",
                  db="vguru_stage")
x = conn.cursor()

try:
   #x.execute("""INSERT INTO anooog1 VALUES (%s,%s)""",(188,90))
   x.execute("""insert into transinfo (ID, ENGINEID, TRANSID, SESSIONID, SESSIONIDCYCLE, TRANSACTIONCOUNT, GRADE_TEXT, UPDATE_TS, QUESTION) values (63, 'VGURUStaging_249', 999999, 999999999, 0, 1, 'UnGraded', '2018-03-07 15:26:39', '\xF0\x9F\x8E\x82')""")
   conn.commit()
except:
   conn.rollback()

conn.close()
