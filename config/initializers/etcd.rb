$etcd = Etcd.client({
  host: ENV['ETCD_HOST'] || Settings.etcd.host,
  port: ENV['ETCD_PORT'] || Settings.etcd.port
})