## HA Kafka Cluster on IBM Container Service


reference [Kafka chart](https://github.com/kubernetes/charts/tree/master/incubator/kafka)

With the following [changes](values.yaml)

* change the zookeeper chart dependency of the cloned chart [requirements.yaml](requirements.yaml) to 0.4.2 from 0.3.1 and execute `helm dep up kafka`
* [option] revise `storageClass` to what `kubectl get storageclasses` returns, e.g. `ibmc-file-bronze` is `default`
* [Option] you can also pre-create the persistenceVolumeClaim, after changing `name` in the [script](../ibm-pvc.yaml).


### Verified 

* Kubernetes 1.7.4
* Kafka Chart 0.2.2
* ZK Chart 0.4.2


### Install the Chart

	helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator
	helm install --name  my-kafka -f  values.yaml incubator/kafka


#### To verify

[test.yaml](test.yaml)

	kubectl create -f test.yaml
	
	kubectl -n default exec testclient -- ./bin/kafka-topics.sh --zookeeper my-kafka-zookeeper:2181 --list
	kubectl -n default exec testclient -- ./bin/kafka-topics.sh --zookeeper my-kafka-zookeeper:2181 --topic test1 --create --partitions 1 --replication-factor 1
	kubectl -n default exec -ti testclient -- ./bin/kafka-console-consumer.sh --bootstrap-server my-kafka-kafka:9092 --topic test1 --from-beginning
	kubectl -n default exec -ti testclient -- ./bin/kafka-console-producer.sh --broker-list my-kafka-kafka-headless:9092 --topic test1


### Known problem

* Zookeeper cluster can not be started with default 0.3.1. Work around by changing dependency to 0.4.2