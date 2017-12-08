## Kubernetes Cluster Federation on IBM Cloud


reference [Kubernetes Cluster Federation](https://kubernetes.io/docs/tasks/federation/set-up-cluster-federation-kubefed/)

with the following key changes:

* Control Plane on Container Service [coredns-provider.conf](coredns-provider.conf): remove `coredns-endpoints`
* Control Plane on ICP [icp-coredns-provider.conf](icp-coredns-provider.conf): use the endpoints from `coredns-coredns`


### Verified 

* Kubernetes 1.7.4
* ETCD Chart 0.5.1: image v0.6.1
* CoreDNS Chart: image  011

Also verified on ICP 

### Deploy Federation with CoreDNS as DNS provider

reference [Deploying CoreDNS and etcd charts on IBM Cloud](../charts/coredns/README.md)

#### Deploy Federation Control Plane on IBM Container Service

##### on IBM Container Service
	
	kubefed init fellowship --host-cluster-context=mycluster-1 --dns-provider="coredns" --dns-zone-name="example.com." --dns-provider-config="$PWD/coredns-provider.conf"
	
##### on ICP

	kubefed init fellowship-icp --host-cluster-context=mycluster.icp-context --dns-provider="coredns" --dns-zone-name="example.com." --dns-provider-config="$PWD/icp-coredns-provider.conf" --etcd-persistent-storage=false --api-server-advertise-address=ICP_HOST --api-server-service-type='NodePort'
	
	
#### Make multiple contexts visible to kubectl

	# when you have the cluster config yml. e.g. downloaded from IBM Container Service Cluster
	
	export KUBECONFIG=~/.bluemix/plugins/container-service/clusters/mycluster-1/xxx-mycluster-1.yml:~/.bluemix/plugins/container-service/clusters/mycluster-1/xxx-mycluster-1.yml:~/.kube/config
	
	# for ICP Cluster, if you manually create the cluster context from `Configure Client`, the current context's config file will be updated
	e.g.
	kubectl config set-cluster mycluster-icp --server=https://ICP_HOST:PORT --insecure-skip-tls-verify=true
	kubectl config set-context mycluster-icp --cluster=mycluster-icp
	kubectl config set-credentials mycluster-icp-user --token=TOKEN
	kubectl config set-context mycluster-icp --user=mycluster-icp-user --namespace=default

	# display all context available for cluster join	
	kubectl config get-contexts
	
#### Add cluster to federation

	
##### with Container Service Control Plane

	# switch context
	kubectl config use-context fellowship

	kubefed join mycluster-1 --host-cluster-context=mycluster-1 
	kubefed join mycluster-2 --host-cluster-context=mycluster-1 
	kubefed join mycluster-icp --host-cluster-context=mycluster-1 

	# display clusters of a federation
	kubectl --context=fellowship get clusters

#####  with ICP Control Plane
	
	# switch context
	kubectl config use-context fellowship-icp

	kubefed join mycluster-icp --host-cluster-context=mycluster-icp
	kubefed join mycluster-1 --host-cluster-context=mycluster-icp
	kubefed join mycluster-2 --host-cluster-context=mycluster-icp

	# display clusters of a federation
	kubectl --context=fellowship get clusters

	
### Known problem


* kubefed command may hit `unable to read certificate-authority xxx.pem for mycluster-fed due to open xxx.pem: no such file or directory`. Copy the pem to execution directory work around the issue
* ICP `kubedef init` hit hung situation withoutu the extra settings
