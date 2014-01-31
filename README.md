# Service Forge

The open source framework for building elastic, persistent services on any infrastructure. Services as a Service. Simple API to allow users to automate the provisioning, configuration and health of a cluster of VMs that provide a service.

     ___              _        ___                 
    / __| ___ _ ___ _(_)__ ___| __|__ _ _ __ _ ___ 
    \__ \/ -_) '_\ V / / _/ -_) _/ _ \ '_/ _` / -_)
    |___/\___|_|  \_/|_\__\___|_|\___/_| \__, \___|
                                         |___/     

Use one of the [community catalog](https://github.com/serviceforge-community) of ServiceForge Services, or build your own!

Fully integrated into Cloud Foundry as a universal Service Broker.


## Project Health

[![Code Climate](https://codeclimate.com/repos/52cee12f69568028a6006386/badges/5b9bd68a2791fdb88339/gpa.png)](https://codeclimate.com/repos/52cee12f69568028a6006386/feed)

## API Examples

Get a list of available services and service plans. [Cloud Foundry v2 compliant]

```
curl -XGET -u cc:secret http://serviceforge.ngrok.com/v2/catalog
```

Create a new service instance [Cloud Foundry v2 compliant]

```
$ curl -XPUT -u cc:secret -F service_id=b9698740-4810-4dc5-8da6-54581f5108c4 -F plan_id=6e8ece8c-4fe6-4d58-9aeb-497d6aeba113 http://serviceforge.ngrok.com/v2/service_instances/my-etdc-server
{"dashboard_url":"http://cc:secret@serviceforge.ngrok.com/service_instances/my-etdc-server"}
```

The `dashboard_url` should be the same URL used to invoke API calls. It is returned to be compliant with the Cloud Foundry v2 API, and to allow Cloud Foundry clients to discover the ServiceForge API endpoint.

NOTE: In future the `dashboard_url` field will stop returning the admin credentials and instead support the Cloud Foundry SSO system for user authentication and authorization.

Create unique end-user credentials for the service and fetch connection information [Cloud Foundry v2 compliant]

```
$ curl -XPUT -u cc:secret -F service_id=b9698740-4810-4dc5-8da6-54581f5108c4 -F plan_id=6e8ece8c-4fe6-4d58-9aeb-497d6aeba113 http://serviceforge.ngrok.com/v2/service_instances/my-etdc-server/service_bindings/my-etcd-server-user-1
{"error":"Service Instance not ready for binding; state deploying"}
```

The previous API call to create the service returns quickly. The service itself may not have completed being provisioned, configured and running.

To poll for the current state of a service instance, say to check until its state changes from `deploying` (above) to `running`:

```
$ curl -XGET -u cc:secret http://serviceforge.ngrok.com/service_instances/my-etdc-server
{"service_id":"b9698740-4810-4dc5-8da6-54581f5108c4","service_instance_id":"my-etdc-server","service_plan_id":"6e8ece8c-4fe6-4d58-9aeb-497d6aeba113","deployment_name":"etcd-my-etdc-server","infrastructure_network":{"ip_range_start":"10.244.2.40","template":"/Users/drnic/Sites/serviceforge/infrastructure_pools/warden/10.244.2.40.yml"},"state":"running","latest_bosh_deployment_task_id":"16"}%
```

The state of the service instance is now `running` so we can try binding again:

```
$ curl -XPUT -u cc:secret -F service_id=b9698740-4810-4dc5-8da6-54581f5108c4 -F plan_id=6e8ece8c-4fe6-4d58-9aeb-497d6aeba113 http://serviceforge.ngrok.com/v2/service_instances/my-etdc-server/service_bindings/my-etcd-server-user-1
{"service_binding_id":"my-etcd-server-user-1","service_instance_id":"my-etdc-server","credentials":{"port":4001,"host":"10.244.2.42"}}
```

The result is compliant with the Cloud Foundry v2 API, and includes the `credentials` information that a client application would need to connect to the running service instance.

In this example, the etcd service was not implemented to support per-user usernames and passwords.

When an end-user application no longer requires the connection credentials, they can be requested to be deleted. [Cloud Foundry v2 compliant]

```
$ curl -XDELETE -u cc:secret http://serviceforge.ngrok.com/v2/service_instances/my-etdc-server/service_bindings/my-etcd-server-user-1
{}
```

And finally, the service instance and all the provisioned infrastructure associated with it can be requested to be deleted. [Cloud Foundry v2 compliant]

```
$ curl -XDELETE -u cc:secret http://serviceforge.ngrok.com/v2/service_instances/my-etdc-server
```

This API currently blocks until the underlying infrastructure is completely destroyed.


## Dependencies

* ruby 1.9.3p484 through to 2.1.0 (development done against 2.1.0)
* etcd 0.2 - [install latest release](https://github.com/coreos/etcd/releases/)
* gcf - [gcf v0.6 beta2](https://github.com/cloudfoundry/cli/releases/tag/v6.0.0-beta2)
* spiff - [spiff v0.3](https://github.com/cloudfoundry-incubator/spiff/releases)

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

```
$ gem install jazor
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

Instead, use a custom subdomain. For this, create a free Ngrok account and on the dashboard, register a subdomain such as "serviceforge-USERNAME":

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
    subdomain: serviceforge-USERNAME
    proto:
      http: 5000
```

You can now run Ngrok with your custom domain and credentials:

```
$ ngrok -config config/environments/development/ngrok.conf start broker
Tunnel Status                 online                                                                                                                                              
Version                       1.6/1.5                                                                                                                                             
Forwarding                    http://serviceforge-drnic.ngrok.com -> 127.0.0.1:5000                                                                                                          
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
$ gcf create-service-broker serviceforge-dev cc secret http://serviceforge.ngrok.com
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
$ gcf delete-service-broker serviceforge-dev
```
