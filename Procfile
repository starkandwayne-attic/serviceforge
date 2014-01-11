web: bin/rails s -p $PORT -P tmp/pids/server-$RAILS_ENV.pid
etcd: etcd -addr=127.0.0.1:${ETCD_PORT:-$PORT} -peer-addr=127.0.0.1:$(expr ${ETCD_PORT:-$PORT} + 1) -name $RAILS_ENV -data-dir=db/etcd-$RAILS_ENV
