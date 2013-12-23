# TODO: make configurable via env var & config file
$etcd = Etcd.client({
  host: ENV['ETCD_HOST'] || Settings.etcd.host,
  port: ENV['ETCD_PORT'] || Settings.etcd.port
})