## Kubernetes Cluster Federation on IBM Cloud


reference [Kubernetes Cluster Federation](https://kubernetes.io/docs/tasks/federation/set-up-cluster-federation-kubefed/)

with the following key changes:

* [coredns-provider.conf](coredns-provider.conf): use endpoints of `coredns-coredns`

### Verified 

* Container Service: Kubernetes 1.7.4, Federation API Server 1.8.4
* ETCD Chart 0.5.1: image v0.6.1
* CoreDNS Chart: image  011

Also verified on ICP 

### Deploy Federation with CoreDNS as DNS provider

#### Deploy CoreDNS with etcd

reference [Deploying CoreDNS and etcd charts on IBM Cloud](../charts/coredns/README.md)

#### Deploy Federation Control Plane on IBM Cloud

##### on IBM Container Service
	
	kubefed init fellowship --host-cluster-context=mycluster-1 --dns-provider="coredns" --dns-zone-name="example.com." --dns-provider-config="$PWD/coredns-provider.conf"
	
##### on ICP

	kubefed init fellowship --host-cluster-context=mycluster-icp --dns-provider="coredns" --dns-zone-name="example.com." --dns-provider-config="$PWD/coredns-provider.conf" --etcd-persistent-storage=false --api-server-advertise-address=ICP_HOST --api-server-service-type='NodePort'
	
	
####  Make sure CoreDNS server in nameserver resolv.conf chain

check `--server=/example.com./COREDNS_IP#53` is defined in `kube-dns-amd64`

	kubectl --context mycluster-kafka edit deploy kube-dns-amd64 -n kube-system
		

#### Make multiple contexts visible to kubectl

	# when you have the cluster config yml. e.g. downloaded from IBM Container Service Cluster
	
	export KUBECONFIG=~/.bluemix/plugins/container-service/clusters/mycluster-1/xxx-mycluster-1.yml:~/.bluemix/plugins/container-service/clusters/mycluster-1/xxx-mycluster-1.yml:~/.kube/config
	
	# for ICP Cluster, if you manually create the cluster context from `Configure Client`, the current context's config file will be updated. e.g.
	kubectl config set-cluster mycluster-icp --server=https://ICP_HOST:PORT --insecure-skip-tls-verify=true
	kubectl config set-context mycluster-icp --cluster=mycluster-icp
	kubectl config set-credentials mycluster-icp-user --token=TOKEN
	kubectl config set-context mycluster-icp --user=mycluster-icp-user --namespace=default

	# display all context available for cluster join	
	kubectl config get-contexts
	
	
#### Add/Remove cluster to federation

	# switch context.
	kubectl config use-context fellowship

	kubefed join mycluster-1 --host-cluster-context=mycluster-1
	kubefed join mycluster-2 --host-cluster-context=mycluster-1
	kubefed join mycluster-icp --host-cluster-context=mycluster-1

	# display clusters of a federation
	kubectl --context=fellowship get clusters
	
	# remove cluster from federation
	kubefed unjoin mycluster-2 --host-cluster-context=mycluster-1

Note: revise `host-cluster-context` to your host cluster context, e.g. `mycluster-icp`
 	
 	
#### Create `default` namespace in federation context

	kubectl get namespace --context=fellowship
	kubectl create namespace default --context=fellowship

	
#### Remove federation 

	kubectl delete ns federation-system --context=fellowship
	
	
### Use case scenarios

Use [test-federation.sh](test-federation.sh) to list pods and services from each federated cluster.

#### Placement through policy using label

[Reference](https://kubernetes.io/docs/tasks/federation/set-up-placement-policies-federation). Need to change secret name in [policy-engine-deployment.yaml](policy-engine-deployment.yaml) to the correct one, e.g `fellowship` instead of `federation`

    # Switch Context
	kubectl config use-context mycluster-1
	
	# Create and config schedule policy 
	kubectl create -f scheduling-policy-admission.yaml
	kubectl -n federation-system edit deployment fellowship-apiserver
		# Change 1 
		from
			- --admission-control=NamespaceLifecycle
		to
			- --admission-control=SchedulingPolicy
			- --admission-control-config-file=/etc/kubernetes/admission/config.yml

		# Change 2
		add under volumes
			- name: admission-config
			  configMap:
			    name: admission

		# Change 3
		add under volumeMounts
			- name: admission-config
			  mountPath: /etc/kubernetes/admission
	
	# Deploy policy engine
	kubectl create -f policy-engine-service.yaml
	kubectl create -f policy-engine-deployment.yaml
	
	kubectl --context=fellowship create namespace kube-federation-scheduling-policy
	kubectl --context=fellowship -n kube-federation-scheduling-policy create configmap scheduling-policy --from-file=policy.rego

Note: you can revise `use-context` to your host cluster context, e.g. `mycluster-icp`

##### Test the placement policy

	# All pods are in one cluster
	
	kubectl --context=fellowship annotate clusters mycluster-1 pci-certified=true
    kubectl --context=fellowship create -f replicaset-example-policy.yaml
	kubectl --context=fellowship get rs nginx-pci -o jsonpath='{.metadata.annotations}'


#### Default placement of even distribution

One every federated context:

	kubectl --context=mycluster-1 run -it --rm --restart=Never --image=infoblox/dnstools:latest dnstools
	
		host YOUR_SERVICE.default.fellowship

##### Example Federated NginX

[reference](https://kubernetes.io/docs/tasks/federation/federation-service-discovery/) or [more in detail](https://github.com/kelseyhightower/kubernetes-cluster-federation/blob/master/labs/07-federated-nginx-service.md)


	# ReplicaSet and Service are created in federation context 
	kubectl --context=fellowship create -f nginx.yaml
	kubectl --context=fellowship get rs -l app=nginx 
	
	# ReplicaSet, Service, pods are created in each federated cluster
	kubectl --context=mycluster-1 get rs,pod,svc -l app=nginx
	kubectl --context=mycluster-2 get rs,pod,svc -l app=nginx
	kubectl --context=mycluster-icp get rs,pod,svc -l app=nginx
	
	# Describe the service endpoint
	kubectl --context=fellowship describe services nginx
	
	# clean up
	kubectl --context=fellowship delete rs,svc -l app=nginx 
	
### TODO

* Cross-cluster service discovery
   
### Known problem


* kubefed command may hit `unable to read certificate-authority xxx.pem for mycluster-fed due to open xxx.pem: no such file or directory`. Copy the pem to execution directory work around the issue
* ICP `kubedef init` hit hung situation withoutu the extra settings
* Joining cluster name can not have `.` in the name. You can `kubeded join` a new cluster name, while using `--cluster-context` to point to the original context.
* To clean up properly, you may need to issue `kubectl delete ns federation-system --context=` against all context involved in the federation
* [Investigate](ICP as Control Plane placement policy not working)

