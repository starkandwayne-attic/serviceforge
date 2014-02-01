# Service Forge

The open source framework for building elastic, persistent services on any infrastructure. Services as a Service. Simple API to allow users to automate the provisioning, configuration and health of a cluster of VMs that provide a service.

     ___              _        ___                 
    / __| ___ _ ___ _(_)__ ___| __|__ _ _ __ _ ___ 
    \__ \/ -_) '_\ V / / _/ -_) _/ _ \ '_/ _` / -_)
    |___/\___|_|  \_/|_\__\___|_|\___/_| \__, \___|
                                         |___/     

Use one of the [community catalog](https://github.com/serviceforge-community) of ServiceForge Services, or build your own!

Fully integrated into Cloud Foundry as a universal Service Broker.

Build your services with open source projects or proprietary. Wrap your running processes in Docker, Warden, bare LXC, or run them directly on the machine.

Project code generators to make it faster to create new services.

Ops tools to help administrators to provide hands-on assistance to running services, such as DBs. Integration options for monitoring, alerting & logging.

ServiceForge's primary focus is on providing an orchestration platform for underlying infrastructure, with a simple user-facing API (including Cloud Foundry integration), and allowing people to write their own configuration management & service technologies.

## Project Health

[![Code Climate](https://codeclimate.com/repos/52cee12f69568028a6006386/badges/5b9bd68a2791fdb88339/gpa.png)](https://codeclimate.com/repos/52cee12f69568028a6006386/feed)

## API Examples

Get a list of available services and service plans. [Cloud Foundry v2 compliant]

```
curl -XGET -u cc:secret http://localhost:5000/v2/catalog
```

Create a new service instance [Cloud Foundry v2 compliant]

```
$ curl -XPUT -u cc:secret -F service_id=b9698740-4810-4dc5-8da6-54581f5108c4 -F plan_id=6e8ece8c-4fe6-4d58-9aeb-497d6aeba113 http://localhost:5000/v2/service_instances/my-etdc-server
{"dashboard_url":"http://cc:secret@localhost:5000/service_instances/my-etdc-server"}
```

The `dashboard_url` should be the same URL used to invoke API calls. It is returned to be compliant with the Cloud Foundry v2 API, and to allow Cloud Foundry clients to discover the ServiceForge API endpoint.

NOTE: In future the `dashboard_url` field will stop returning the admin credentials and instead support the Cloud Foundry SSO system for user authentication and authorization.

Create unique end-user credentials for the service and fetch connection information [Cloud Foundry v2 compliant]

```
$ curl -XPUT -u cc:secret -F service_id=b9698740-4810-4dc5-8da6-54581f5108c4 -F plan_id=6e8ece8c-4fe6-4d58-9aeb-497d6aeba113 http://localhost:5000/v2/service_instances/my-etdc-server/service_bindings/my-etcd-server-user-1
{"error":"Service Instance not ready for binding; state deploying"}
```

The previous API call to create the service returns quickly. The service itself may not have completed being provisioned, configured and running.

To poll for the current state of a service instance, say to check until its state changes from `deploying` (above) to `running`:

```
$ curl -XGET -u cc:secret http://localhost:5000/service_instances/my-etdc-server
{"service_id":"b9698740-4810-4dc5-8da6-54581f5108c4","service_instance_id":"my-etdc-server","service_plan_id":"6e8ece8c-4fe6-4d58-9aeb-497d6aeba113","deployment_name":"etcd-my-etdc-server","infrastructure_network":{"ip_range_start":"10.244.2.40","template":"/Users/drnic/Sites/serviceforge/infrastructure_pools/warden/10.244.2.40.yml"},"state":"running","latest_bosh_deployment_task_id":"16"}%
```

The state of the service instance is now `running` so we can try binding again:

```
$ curl -XPUT -u cc:secret -F service_id=b9698740-4810-4dc5-8da6-54581f5108c4 -F plan_id=6e8ece8c-4fe6-4d58-9aeb-497d6aeba113 http://localhost:5000/v2/service_instances/my-etdc-server/service_bindings/my-etcd-server-user-1
{"service_binding_id":"my-etcd-server-user-1","service_instance_id":"my-etdc-server","credentials":{"port":4001,"host":"10.244.2.42"}}
```

The result is compliant with the Cloud Foundry v2 API, and includes the `credentials` information that a client application would need to connect to the running service instance.

In this example, the etcd service was not implemented to support per-user usernames and passwords.

When an end-user application no longer requires the connection credentials, they can be requested to be deleted. [Cloud Foundry v2 compliant]

```
$ curl -XDELETE -u cc:secret http://localhost:5000/v2/service_instances/my-etdc-server/service_bindings/my-etcd-server-user-1
{}
```

And finally, the service instance and all the provisioned infrastructure associated with it can be requested to be deleted. [Cloud Foundry v2 compliant]

```
$ curl -XDELETE -u cc:secret http://localhost:5000/v2/service_instances/my-etdc-server
```

This API currently blocks until the underlying infrastructure is completely destroyed.

### API overview

The current API looks like:

* GET    /v2/catalog
* PATCH  /v2/service_instances/:service_instance_id/service_bindings/:id
* PUT    /v2/service_instances/:service_instance_id/service_bindings/:id
* DELETE /v2/service_instances/:service_instance_id/service_bindings/:id
* PATCH  /v2/service_instances/:id
* PUT    /v2/service_instances/:id
* DELETE /v2/service_instances/:id
* GET    /service_instances/:id

Notice that the first 7 APIs which begin with `/v2`. These are the Cloud Foundry compliant API endpoints. The other APIs are additional. ServiceForge wants to continue to be a fully-compliant Cloud Foundry service broker; whilst also exploring new realms of awesome functionality. API design is hard. Help appreciated.

## Architecture

Service Forge is an HTTP web app that uses [etcd](https://github.com/coreos/etcd) for DB storage and [BOSH](http://bosh.cloudfoundry.org/) for orchestration of target infrastructures.

     +-------------------+      +------------------+      +-------------------+
     |                   |      |                  |      |                   |
     |                   |      |                  |      |  OpenStack/       |
     |   Service Forge   |+---->|   BOSH           |+---->|  PistonCloud/     |
     |                   |      |                  |      |  etc              |
     |                   |      |                  |      |                   |
     +-------------------+      +------------------+      +-------------------+
           +         +  +
           |         |  |
           |         |  |       +------------------+      +-------------------+
           v         |  |       |                  |      |                   |
     +------------+  |  |       |                  |      |                   |
     |            |  |  +------>|   BOSH           |+---->|  AWS EC2 & VPC    |
     |  etcd      |  |          |                  |      |                   |
     |            |  |          |                  |      |                   |
     +------------+  |          +------------------+      +-------------------+
                     |
                     |
                     |          +------------------+      +-------------------+
                     |          |                  |      |                   |
                     |          |                  |      |                   |
                     +--------->|   BOSH           |+---->|  vSphere          |
                                |                  |      |                   |
                                |                  |      |                   |
                                +------------------+      +-------------------+

### Cloud Foundry Service Broker

Service Forge can be integrated with a private Cloud Foundry installation as a service broker. At a high-level, this looks like:

                      +-------------------+           +-------------------+
                      |                   |           |                   |
                      |                   |           |                   |
    Superpowered      | Cloud Foundry     +---------->|   Service Forge   |
    CF CLI    +------>| Cloud Controller  |           |                   |
                      |                   |           |                   |
                      +-------------------+           +-------------------+

## Cloud Foundry CLI

To support the additional functionality of ServiceForge, an extended CLI is provided for Cloud Foundry users. It is a fork of the Cloud Foundry [cli](https://github.com/cloudfoundry/cli) written in the Go language. An attempt is made to keep versions of the extended CLI kept up-to-date with new version of the basic Cloud Foundry CLI.

The features of the CLI that are extended:

* `gcf services` - shows an additional table column for the running state of the service
* `gcf create-service` - waits patiently until the service instance is completely provisioned and the underlying BOSH deployment has completed. Uses the `dashboard_url` as its mechanism for polling for the running state of the service instance.

## Installing Service Releases

Once you have ServiceForge running (which includes one or more BOSHs, one per target infrastructure/region/account), you will need to install Service Releases. Service Releases are built to be independent of your target infrastructure and independent of the Internet. That's right, you can install any Service Release into a private, locked-down data center running OpenStack or vSphere.

You can find open source, community-contributed Service Releases in the [ServiceForge Community](https://github.com/serviceforge-community) organization on GitHub. There may also be commercially sold Service Releases. Finally, you may wish to [author your own Service Releases](#authoring-services).

There may be automated tools to simplify the installation of Service Releases in future. The following steps are the granular steps to install a new Service Release.

1. Install BOSH releases to BOSH

  Each Service Release may be composed of one or more BOSH Releases. You will be provided with one or more `tgz` files that are BOSH releases. To install each one:

  ```
  bosh upload release RELEASE-VERSION.tgz
  ```

1. Install BOSH stemcells to BOSH

  Each Service Release will require at least one BOSH stemcell (and most Service Releases will only use a single BOSH stemcell) which represents a base server image, such as Ubuntu or CentOS. These may be either distributed with the Service Release, or be available from the public list of BOSH stemcells. They are distributed as `tgz` files.

  To find a list of stemcells and then download a public shared stemcell:

  ```
  bosh public stemcells
  bosh download public stemcell bosh-stemcell-1868-aws-xen-ubuntu.tgz
  ```

  To install a stemcell:

  ```
  bosh upload stemcell bosh-stemcell-1868-aws-xen-ubuntu.tgz
  ```

  BOSH will then convert this into a native image for the target infrastructure. For example, it will create an AMI in the target region of AWS in the example above.

1. Install Service Metadata & Spiff templates to ServiceForge

  Another `tgz` file that contains a collection of YAML files. They include a metadata file describing the Service and different Service Plans, plus the YAML templates (called Spiff templates) that will be used to instruct BOSH how to deploy your BOSH release. 

  You upload these to ServiceForge:

  ```
  serviceforge install serviceforge-RELEASE-VERSION.tgz
  ```

## Authoring services

Perhaps the most interesting aspect of ServiceForge is to create and publish services. There are many ways to configure Postgresql or Cassandra, and so there may be many ServiceForge Services for each technology. There is a [community catalog](https://github.com/serviceforge-community) that you might like to share with, or help contribute to. Alternately, if you're writing new services then these may be useful examples to learn from.

### What is provided?

When preparing to author a service, it may be useful to know what ServiceForge & BOSH provides your service when it is up and running.

* **Automation for provisioning servers** on supported IaaS (such as AWS, OpenStack, vSphere)
* Automation for managing the **networking bindings of servers**. For example, if a single network is to be shared across all ServiceForge running services (single VMs, or clusters of dozens of machines), then ServiceForge will automate the allocation of IPs to each server.
* A **persistent disk** (such as an EBS volume on AWS) will be mounted at `/var/vcap/store` on each server. This volume is where your service should store persistent data. ServiceForge & BOSH will automatically unmount this disk and remount it new VMs when end-users resize their servers, or upgrade the base operating system kernel. Similarly, if the server is killed (by the infrastructure provider or an administrator) and BOSH resurrects the server, the persistent disk will be remounted.
* An **ephemeral disk** (such as a local disk on the VMs host machine) will be mounted at `/var/vcap/data` on each server. This volume is where your service should store log files and other temporary data.
* **Processes are monitored** (to start and keep running) via [monit](http://mmonit.com/monit/). In the simple case, you would use monit to run the service daemon, such as PostgreSQL or Cassandra/Java. If you want to dynamically create/remove processes, then you would author a fancy agent thingy that itself would be monitored by monit; and you'd want to perhaps use an additional monitoring service. Say, like monit. SO MANY LAYERS! Your call. Keep it simple and static or make is fancy and dynamic. You get monit and you need to use it for the top level processes.
* **Processes can be configured** with configuration files. You provide the templates when you author the service and ServiceForge & BOSH will apply the runtime data to them before the processes are started. Just like writing a Chef cookbook, but without Ruby code in the Chef cookbook, I guess. Just the template files.
* You'll want to tell monit how to run your service's processes. You'll do that in one of the template files. You'll see where. There's a generator to get you started. You'll figure it out quickly.
* **Versioned upgrades of running services.** Each running service can independently manage the upgrade of its packages and configuration files. Service Authors can confidently release new versions. Service users determine if/when to trigger upgrades.
* **Base images for servers** that are available for all target infrastructures. Thanks to BOSH, ServiceForge offers Service Authors consistent base images for your services to use. Regardless of the target infrastructure that someone is using to run your service (AWS, vSphere, OpenStack) they will be using the same base image. Currently there are Ubuntu & CentOS base images.

### What are the artifacts for a Service Release?

See the section [Installing Service Releases](#installing-service-releases) for a Service Installer's view of the artifacts that they install into ServiceForge & BOSH.

In summary:

* BOSH releases - complete distribution of all packages, configuration file templates and executable scripts that describes how a Service is implemented
* BOSH stemcell - the base image of servers. Either provide a custom stemcell or reference a public Ubuntu or CentOS base image
* Spiff templates - various portions of configuration that are specific to: each supported infrastructure, networking, the specific Service, each provided Service Plan, and for each Service Binding User.
* Metadata - documenting the available Service and each Service Plan. This will reference the other assets above.


## Dependencies

* BOSH/MicroBOSH/bosh-lite
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
