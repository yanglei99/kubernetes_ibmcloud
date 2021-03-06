## Kubernetes Cluster Federation on IBM Cloud


reference [Kubernetes Cluster Federation](https://kubernetes.io/docs/tasks/federation/set-up-cluster-federation-kubefed/)

with the following key changes:

* [coredns-provider.conf](coredns-provider.conf): use the coredns node public IP and port.

* [cm-kube-dns.yaml](cm-kube-dns.yaml): make sure each federated cluster has `kube-dns` configMap with `stubDomains example.com` and coredns node public IP and port


### Verified 

* Container Service: Kubernetes 1.8.4
* ICP 2.1.0 : Kubernetes 1.8.3 
* Kubefed: 1.8.4
* ETCD chart 0.5.1, image 0.6.1
* CoreDNS Chart 0.7.0


### Deploy Federation with CoreDNS as DNS provider

You can create [ICP Cluster with federation directly](https://github.com/yanglei99/terraform_ibmcloud/tree/master/icp). 

#### Deploy CoreDNS with etcd

Select one of clusters as federation host. 

reference [Deploying CoreDNS and etcd charts on IBM Cloud](../charts/coredns/README.md)

#### Deploy Federation Control Plane

##### on IBM Container Service
	
	kubefed init fellowship --host-cluster-context=mycluster-1 --dns-provider="coredns" --dns-zone-name="example.com." --dns-provider-config="coredns-provider.conf"
		
##### on ICP

	kubefed init fellowship --host-cluster-context=mycluster-icp --dns-provider="coredns" --dns-zone-name="example.com." --dns-provider-config="coredns-provider.conf" --etcd-persistent-storage=false --api-server-advertise-address=ICP_HOST --api-server-service-type='NodePort'
	

#### Make multiple contexts visible to kubectl

	# when you have the cluster config yml. e.g. downloaded from IBM Container Service Cluster
	
	export KUBECONFIG=~/.bluemix/plugins/container-service/clusters/mycluster-1/xxx-mycluster-1.yml:~/.bluemix/plugins/container-service/clusters/mycluster-1/xxx-mycluster-1.yml:kubeconfig
	
	# for ICP Cluster, if you manually create the cluster context from `Configure Client`, the current context's config file will be updated. e.g.
	kubectl config set-cluster mycluster-icp --server=https://ICP_HOST:PORT --insecure-skip-tls-verify=true
	kubectl config set-context mycluster-icp --cluster=mycluster-icp
	kubectl config set-credentials mycluster-icp-user --token=TOKEN
	kubectl config set-context mycluster-icp --user=mycluster-icp-user --namespace=default

	# display all context available for cluster join	
	kubectl config get-contexts
	
	
#### Add/Remove cluster to federation

Use your `host-cluster-context`. e.g. `mycluster-icp`

	# switch context.
	kubectl config use-context fellowship

	kubefed join mycluster-1 --host-cluster-context=mycluster-1
	kubefed join mycluster-2 --host-cluster-context=mycluster-1
	kubefed join mycluster-icp --host-cluster-context=mycluster-1

	# display clusters of a federation
	kubectl --context=fellowship get clusters
	
	# update kube-dns ConfigMap as needed and restart kube-dns
	kubectl apply -f cm-kube-dns.yaml --context=mycluster-1
	kubectl apply -f cm-kube-dns.yaml --context=mycluster-2
	kubectl apply -f cm-kube-dns.yaml --context=mycluster-icp
	
	# remove cluster from federation
	kubefed unjoin mycluster-2 --host-cluster-context=mycluster-1

 	
#### Create `default` namespace in federation context as needed

	kubectl get namespace --context=fellowship
	kubectl create namespace default --context=fellowship

	
#### Remove federation 

On every federated cluster

	kubectl delete ns federation-system --context=YOUR_CONTEXT
	
	
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


##### Test the placement policy

	# All pods are in one cluster
	
	kubectl --context=fellowship annotate clusters mycluster-1 pci-certified=true
    kubectl --context=fellowship create -f replicaset-example-policy.yaml
	kubectl --context=fellowship get rs nginx-pci -o jsonpath='{.metadata.annotations}'


#### Default placement of even distribution

[reference](https://kubernetes.io/docs/tasks/federation/federation-service-discovery/) or [more in detail](https://github.com/kelseyhightower/kubernetes-cluster-federation/blob/master/labs/07-federated-nginx-service.md)

	# ReplicaSet and Service are created in federation context 
	kubectl --context=fellowship create -f nginx.yaml
	
	# Describe the service
	kubectl --context=fellowship describe services nginx

	# clean up
	kubectl --context=fellowship delete rs,svc -l app=nginx 


#### Cross-Cluster Service Discovery

On every federated cluster:

	kubectl --context=mycluster-1 run -it --rm --restart=Never --image=infoblox/dnstools:latest dnstools
	
		# Use the federated DNS name
		
		host nginx.default.fellowship
	
		# re-label cluster
		kubectl label --all nodes failure-domain.beta.kubernetes.io/region=us  --overwrite --context mycluster-1 
		kubectl label --all nodes failure-domain.beta.kubernetes.io/zone=east --overwrite --context mycluster-1

		kubectl label --all nodes failure-domain.beta.kubernetes.io/region=us   --overwrite --context mycluster2
		kubectl label --all nodes failure-domain.beta.kubernetes.io/zone=west  --overwrite --context mycluster2
		
		# Lookup cluster NDS name
		host nginx.default.fellowship.svc.example.com
		host nginx.default.fellowship.svc.east.us.example.com
		host nginx.default.fellowship.svc.west.us.example.com

#### Micro-Service on Federation

Reference [Acmeair MicroService](https://github.com/yanglei99/acmeair-nodejs/blob/master/document/k8s/acmeair-ms-fed.yaml)

### Known problem

* kubefed command may hit `unable to read certificate-authority xxx.pem for mycluster-1 due to open xxx.pem: no such file or directory`. Copy the pem to execution directory work around the issue
* To clean up properly, you may need to issue `kubectl delete ns federation-system --context=` against all context involved in the federation
* Joining cluster name can not have `.` in the name. You can `kubeded join` a new cluster name, while using `--cluster-context` to point to the original context.
* ICP Service Discovery does not work
