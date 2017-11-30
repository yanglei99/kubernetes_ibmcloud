## Zookeeper Cluster on IBM Container Service


reference [Zookeeper chart](https://github.com/kubernetes/charts/tree/master/incubator/zookeeper)

With the following [changes](values.yaml)

* [option] revise `storageClass` to what `kubectl get storageclasses` returns, e.g. `ibmc-file-bronze` is `default`
* [Option] you can also pre-create the persistenceVolumeClaim, after changing `name` in the [script](../ibm-pvc.yaml).


### Verified 

* Kubernetes 1.7.4
* Zookeeper Chart 0.4.2


### Install the Chart

	helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator
	helm install --name  my-kafka -f  values.yaml incubator/zookeeper

#### To Verify

	kubectl exec my-kafka-zookeeper-0 -- /opt/zookeeper/bin/zkCli.sh create /foo bar;
	kubectl exec my-kafka-zookeeper-2 -- /opt/zookeeper/bin/zkCli.sh get /foo;

	kubectl run --attach bbox --image=busybox --restart=Never -- sh -c 'while true; do for i in 0 1 2; do echo zk-${i} $(echo stats | nc my-kafka-zookeeper-${i}.my-kafka-zookeeper-headless:2181 | grep Mode); sleep 1; done; done';
	
	
### Known problem
