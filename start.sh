#!/bin/bash
#
# Install pymysql and then run the script.

pip --quiet --disable-pip-version-check install pymysql
python connect.py
