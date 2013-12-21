# ServAAS

Services as a Service. Service Broker for Cloud Foundry that is backed by BOSH.

## Dependencies

* ruby 1.9+
* etcd 0.2.rc3 - [install latest release](https://github.com/coreos/etcd/releases/)
* Redis 2.8.3+ - [install latest release](http://redis.io/download)

## Run locally

```
$ foreman start -e config/environments/development/procfile.env
```

* You can now access the Service Broker at [http://localhost:5000](http://localhost:5000).

* You can now connect to etcd via the `etcdctl` CLI:

    ```
    $ etcdctl -C 127.0.0.1:5200
    ```

* You can now connect to redis via the `redis-cli` CLI:

    ```
    $ redis-cli -p 5100
    ```

## Running Tests

