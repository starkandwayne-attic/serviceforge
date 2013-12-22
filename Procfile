web: bin/rails s -p $PORT
redis: redis-server config/environments/$RAILS_ENV/redis.conf --port $PORT
etcd: etcd -addr=127.0.0.1:${ETCD_PORT:-$PORT} -peer-addr=127.0.0.1:$(expr ${ETCD_PORT:-$PORT} + 1) -n $RAILS_ENV -data-dir=db/etcd-$RAILS_ENV
