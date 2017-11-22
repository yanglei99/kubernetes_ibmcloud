## HA Kafka Cluster on IBM Container Service


reference [Kafka chart](https://github.com/kubernetes/charts/tree/master/incubator/kafka)

With the following [changes](values.yaml)

* revise `storageClass` to what `kubectl get storageclasses` returns, e.g. `storageClass: ibmc-file-bronze`
* change the zookeeper [chart dependency](requirements.yaml) to 0.4.2 from 0.3.1 and execute `helm dep up kafka`
* [Option] you can also pre-create the persistenceVolumeClaim, after changing `name` in the [script](../ibm-pvc.yaml).


###Verified 

* Kubernetes 1.7.4
* Kafka Chart 0.2.2


### Install the Chart

	helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator
	helm install --name  my-kafka -f  values.yaml incubator/kafka


#### To verify

	kubectl create -f test.yaml
	
	kubectl  exec -ti testclient -- ./bin/kafka-topics.sh --zookeeper my-kafka-zookeeper:2181 --create --replication-factor 1 --partitions 1 --topic mytopic
	kubectl  exec -ti testclient -- ./bin/kafka-topics.sh --zookeeper my-kafka-zookeeper:2181 --list


### Known problem

* Zookeeper cluster can not be started with default 0.3.1. Work around by changing dependency to 0.4.2