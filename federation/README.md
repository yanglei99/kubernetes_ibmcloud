## Kubernetes Cluster Federation on IBM Cloud


reference [Kubernetes Cluster Federation](https://kubernetes.io/docs/tasks/federation/set-up-cluster-federation-kubefed/)


###Verified 

* Kubernetes 1.7.4
* ETCD Chart 0.5.1: image v0.6.1
* CoreDNS Chart: image  011



### Deploy Federation with CoreDNS as DNS provider

reference [Deploying CoreDNS and etcd charts on IBM Cloud](../charts/coredns/README.md)

#### Federation Control Plane on IBM Container Service

##### Federation Control Plane
	
	kubefed init fellowship --host-cluster-context=mycluster-1 --dns-provider="coredns" --dns-zone-name="example.com." --dns-provider-config="$PWD/coredns-provider.conf"
	
##### Make multiple contexts visible to kubectl

	# for IBM Container Service Cluster
	export KUBECONFIG=~/.bluemix/plugins/container-service/clusters/mycluster-1/xxx-mycluster-1.yml:~/.bluemix/plugins/container-service/clusters/mycluster-1/xxx-mycluster-1.yml
	
	# for ICP Cluster, manually create the cluster context from `Configure Client` if you do not have the config yml file
	e.g.
	kubectl config set-cluster mycluster-icp --server=https://HOST:PORT --insecure-skip-tls-verify=true
	kubectl config set-context mycluster-icp --cluster=mycluster-icp
	kubectl config set-credentials mycluster-icp-user --token=TOKEN
	kubectl config set-context mycluster-icp --user=mycluster-icp-user --namespace=default

	# display all context available for cluster join	
	kubectl config get-contexts
	
##### Add cluster to federation

	# switch context
	kubectl config use-context fellowship
	
	# join cluster
	kubefed join mycluster-1 --host-cluster-context=mycluster-1 
	kubefed join mycluster-2 --host-cluster-context=mycluster-1 
	kubefed join mycluster-icp --host-cluster-context=mycluster-1 

	# display clusters of a federation
	kubectl --context=fellowship get clusters

	

### Known problem


* kubefed command may hit `unable to read certificate-authority xxx.pem for mycluster-fed due to open xxx.pem: no such file or directory`. Copy the pem to execution directory work around the issue
