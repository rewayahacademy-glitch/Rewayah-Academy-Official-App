#!/bin/sh
# usage: run_all.sh <tpl_db> <dir> <out>
export PGHOST=127.0.0.1 PGPORT=5544 PGUSER=postgres
TPL=$1; DIR=$2; OUT=$3; : > $OUT
for f in $DIR/scenarios_*.sql; do
  n=$(basename $f .sql); db=sc_$$_$n
  psql -qc "drop database if exists $db" -c "create database $db template $TPL" >/dev/null 2>&1
  r=$(psql -d $db -v ON_ERROR_STOP=1 -f $f 2>&1 >/dev/null | grep -E "ERROR" | head -1 | cut -c1-260)
  if [ -z "$r" ]; then echo "OK   $n" >> $OUT; else echo "RED  $n :: $r" >> $OUT; fi
  psql -qc "drop database $db" >/dev/null 2>&1
done
echo DONE >> $OUT
