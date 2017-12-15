## CoreDNS on IBM Container Service


reference [Deploying CoreDNS and etcd charts](https://kubernetes.io/docs/tasks/federation/set-up-coredns-provider-federation/)

With the following key changes:

* [values.yaml](values.yaml): `serviceProtocol: "TCP"`


### Verified 

* Kubernetes: v1.7.4, v1.8.4
* ETCD Chart 0.5.1: image v0.6.1
* CoreDNS Chart: image  011

Also verified on ICP

### Install ETCD Chart

	helm install stable/etcd-operator --set image.tag=v0.6.1 --name myetcd
	helm upgrade myetcd stable/etcd-operator --set cluster.enabled=true  --set image.tag=v0.6.1

#### To Test

	kubectl run --rm -i --tty --env="ETCDCTL_API=3" --env="ETCDCTL_ENDPOINTS=http://etcd-cluster-client:2379" etcd-test --image quay.io/coreos/etcd --restart=Never -- /bin/sh -c 'watch -n5 "etcdctl  member list"'

	kubectl run --rm -i --tty --env ETCDCTL_API=3 etcd-test --image quay.io/coreos/etcd --restart=Never -- /bin/sh
		# etcdctl --endpoints http://etcd-cluster-client:2379 put foo bar
		# etcdctl --endpoints http://etcd-cluster-client:2379 get foo
		# exit

### Install CoreDNS Chart

	helm install --name coredns -f values.yaml stable/coredns
	
#### To Test
	kubectl run -it --rm --restart=Never --image=infoblox/dnstools:latest dnstools
		# host kubernetes


### Known problem
