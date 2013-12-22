# ServAAS

Services as a Service. Service Broker for Cloud Foundry that is backed by BOSH.

## Dependencies

* ruby 1.9+
* etcd 0.2.rc3 - [install latest release](https://github.com/coreos/etcd/releases/)
* Redis 2.8.3+ - [install latest release](http://redis.io/download)

## Run locally

```
$ bundle install --local --binstubs vendor/bundle/bin
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

### Add local dev broker into your Cloud Foundry

You can add your in-development broker into any Cloud Foundry that you are admin of - bosh-lite or hosted. First, you'll need a publicly accessible URL that your Cloud Controller.

One option is to use [ngrok](https://ngrok.com/) to create a local tunnel from the internet to your machine.

After installation, in one terminal run:

```
$ ngrok 5000
Tunnel Status                 online                                                                                                                                              
Version                       1.6/1.5                                                                                                                                             
Forwarding                    http://77218862.ngrok.com -> 127.0.0.1:5000                                                                                                         
Forwarding                    https://77218862.ngrok.com -> 127.0.0.1:5000                                                                                                        
...
```

You can now use `http://77218862.ngrok.com` (or whatever random URL you are given) to register your local service broker to your external or bosh-lite Cloud Foundry:

```
$ gcf delete-service-broker etcd-dev # only if already registered at a previous ngrok URL
$ gcf create-service-broker etcd-dev cc secret http://77218862.ngrok.com
```

You now need to make each service plan public so users can provision and bind them. To do this you currently need to get the internal service IDs. Then update the cloud controller `public` attribute for each service plan to `true`.

Note: this uses the old `cf` gem to get the `cf curl` command.

```
$ gem install cf jazor
$ cf curl get "/v2/services?inline-relations-depth=1" | jazor "resources[0].entity.service_plans.map {|sp| sp.metadata.url }"
[
  "/v2/service_plans/d7cd19cc-8949-4ad5-bf9a-9e2dc8a857dc",
  "/v2/service_plans/9b8bf544-eca7-4233-b814-37031b7502ac",
  "/v2/service_plans/c4dc469e-724b-4cc4-b696-3d085953f0b2"
]
```

Now, for each result change them to public:

```
$ service_plan="d7cd19cc-8949-4ad5-bf9a-9e2dc8a857dc"
$ cf curl PUT /v2/service_plans/$service_plan -b '{"public":'true'}'
```

The service plans are now visible:

```
$ gcf marketplace
service          plans                            description                                                                               
etcd-dedicated   1-server, 5-servers, 3-servers   etcd: A highly-available key value store...
```

## Running Tests

