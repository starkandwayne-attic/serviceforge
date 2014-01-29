# Nameless

The nameless project. Name me!

Services as a Service. Service Broker for Cloud Foundry that is backed by BOSH.

     _   _                      _               
    | \ | |                    | |              
    |  \| | __ _ _ __ ___   ___| | ___  ___ ___ 
    | . ` |/ _` | '_ ` _ \ / _ \ |/ _ \/ __/ __|
    | |\  | (_| | | | | | |  __/ |  __/\__ \__ \
    |_| \_|\__,_|_| |_| |_|\___|_|\___||___/___/


## Project Health

[![Code Climate](https://codeclimate.com/repos/52cee12f69568028a6006386/badges/5b9bd68a2791fdb88339/gpa.png)](https://codeclimate.com/repos/52cee12f69568028a6006386/feed)

## Dependencies

* ruby 1.9+
* etcd 0.2 - [install latest release](https://github.com/coreos/etcd/releases/)
* Redis 2.8.3+ - [install latest release](http://redis.io/download)

## Run locally

```
$ bundle install --local --binstubs vendor/bundle/bin
$ foreman start -e config/environments/development/procfile.env
```

* You can now access the Service Broker at [http://localhost:5000](http://localhost:5000).

* You can now connect to etcd via the `etcdctl` CLI:

    ```
    $ etcdctl -C 127.0.0.1:5100
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
$ ./bin/mark_all_public
```

The service plans are now visible:

```
$ gcf marketplace
service          plans                            description                                                                               
etcd-dedicated   1-server, 5-servers, 3-servers   etcd: A highly-available key value store...
```

You can now provision a service:

```
$ gcf create-service etcd-dedicated    5-servers my-5-pack
```

### Custom ngrok subdomain to allow restarts

If you stop/restart your ngrok tunnel, you will be given a new URL and you will need to update the `broker_url` for your Cloud Controller Service Broker.

Instead, use a custom subdomain. For this, create a free Ngrok account and on the dashboard, register a subdomain such as "servaas-USERNAME":

![register-subdomain](https://www.evernote.com/shard/s3/sh/37aea898-fa01-46fb-9d38-f3bfcff9372f/4ac10117d828f5e8e8686df4306c3b34/deep/0/ngrok---secure-introspectable-tunnels-to-localhost.png)

There is an example ngrok configuration file. Clone it:

```
$ cp config/environments/development/ngrok.conf.example config/environments/development/ngrok.conf
```

Now edit to add your subdomain, and your Ngrok auth token (from the dashboard).

``` yaml
auth_token: MY_TOKEN
tunnels:
  broker:
    subdomain: servaas-USERNAME
    proto:
      http: 5000
```

You can now run Ngrok with your custom domain and credentials:

```
$ ngrok -config config/environments/development/ngrok.conf start broker
Tunnel Status                 online                                                                                                                                              
Version                       1.6/1.5                                                                                                                                             
Forwarding                    http://servaas-drnic.ngrok.com -> 127.0.0.1:5000                                                                                                          
Web Interface                 127.0.0.1:4040                                                                                                                                      
# Conn                        0                                                                                                                                                   
Avg Conn Time                 0.00ms
```

## Adding new services

1. Add an integration/request spec for the service in `spec/requests/cloud_foundry/v2/lifecycle_NAME_warden_spec.rb`
1. Copy the spiff templates for the release into a `releases/NAME/templates` folder.
1. Add a bosh-lite/warden service into `config/settings.yml`.
1. [Generate a GUID](http://www.guidgenerator.com/online-guid-generator.aspx "Online GUID Generator") for the service, and GUIDs for each service plan for Warden service.


## Running Tests

The integration tests require `etcd` to be running.

```
$ foreman start -e config/environments/test/procfile.env
$ guard
```

## Demo

Assumes you have an app, such as https://github.com/cloudfoundry-community/service-binding-proxy, already deployed.

```
$ git clone https://github.com/cloudfoundry-community/service-binding-proxy /tmp/service-binding-proxy
$ cd /tmp/service-binding-proxy
$ bundle
$ gcf push service-binding-proxy
$ export appname=service-binding-proxy
```

```
$ gcf create-service-broker servaas-dev cc secret http://servaas.ngrok.com
$ ./bin/mark_all_public
$ gcf create-service redis-dedicated    1-server redis-1

# as an admin:
$ bosh task last

$ gcf create-service redis-dedicated    3-servers redis-3

# as an admin:
$ bosh task last

$ gcf bind-service $appname redis-1
$ gcf bind-service $appname redis-3
$ gcf restart $appname
$ curl http://service-binding-proxy.10.244.0.34.xip.io

$ gem install jazor
$ curl http://service-binding-proxy.10.244.0.34.xip.io | jazor

$ gcf unbind-service $appname redis-1
$ gcf delete-service redis-1
$ gcf unbind-service $appname redis-3
$ gcf delete-service redis-3
```

You can now remove the broker with:

```
$ gcf delete-service-broker servaas-dev
```
