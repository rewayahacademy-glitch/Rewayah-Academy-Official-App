#!/bin/sh
# usage: replay.sh <git-ref> <name>   -> builds template db tpl_<name>, runs scenarios, writes /tmp/scn/<name>_results.txt
export PGHOST=127.0.0.1 PGPORT=5544 PGUSER=postgres
REF=$1; N=$2; D=/tmp/rep/$N; rm -rf $D; mkdir -p $D
cd /home/user/Rewayah-Academy-Official-App && git archive $REF supabase | tar -x -C $D
psql -qc "drop database if exists tpl_$N" -c "create database tpl_$N" >/dev/null 2>&1
sed "/^create role/d" $D/supabase/tests/stub_auth.sql > $D/stub_patched.sql; psql -q -d tpl_$N -v ON_ERROR_STOP=1 -f $D/stub_patched.sql >/dev/null 2>$D/stub.err || { echo "STUBFAIL $N" > /tmp/scn/${N}_results.txt; exit 1; }
psql -q -d tpl_$N -c "create publication supabase_realtime" >/dev/null 2>&1
for f in $(ls $D/supabase/migrations/*.sql | sort); do
  psql -q -d tpl_$N -v ON_ERROR_STOP=1 -f $f >/dev/null 2>$D/mig.err || { echo "MIGFAIL $f :: $(grep ERROR $D/mig.err | head -1)" > /tmp/scn/${N}_results.txt; exit 1; }
done
/tmp/scn/run_all.sh tpl_$N $D/supabase/tests /tmp/scn/${N}_results.txt
