# TODO: make configurable via env var & config file
$etcd = Etcd.client(port: ENV['ETCD_PORT'])