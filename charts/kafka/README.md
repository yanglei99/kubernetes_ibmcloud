## HA Kafka Cluster on IBM Container Service


reference [Kafka chart](https://github.com/kubernetes/charts/tree/master/incubator/kafka)

With the following [changes](values.yaml)

* [option] revise `persistence.storageClass` to what `kubectl get storageclasses` returns. e.g. "default"
* [Option] you can also pre-create the persistenceVolumeClaim, after changing `name` in the [script](../ibm-pvc.yaml).


### Verified 

* Kubernetes 1.9.3
* Kafka Chart 0.6.0
* ZK Chart 0.5.0


### Install the Chart

	helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator
	helm install --name  my-kafka -f  myvalues.yaml incubator/kafka


#### To verify

[test.yaml](test.yaml)

	kubectl create -f test.yaml

    # list all kafka topics:
	kubectl -n default exec testclient -- /usr/bin/kafka-topics --zookeeper my-kafka-zookeeper:2181 --list

	# To create a new topic:
	kubectl -n default exec testclient -- /usr/bin/kafka-topics --zookeeper my-kafka-zookeeper:2181 --topic test1 --create --partitions 1 --replication-factor 1

	# To listen for messages on a topic and Ctrl+C to stop:
	kubectl -n default exec -ti testclient -- /usr/bin/kafka-console-consumer --bootstrap-server my-kafka-kafka:9092 --topic test1 --from-beginning

	# To start an interactive message producer session:
	kubectl -n default exec -ti testclient -- /usr/bin/kafka-console-producer --broker-list my-kafka-kafka-headless:9092 --topic test1

	# To view JMX configuration (pull request/updates to improve defaults are encouraged):
	kubectl -n default describe configmap my-kafka-kafka-metrics


### Monitoring

[Promethues and Grafana](prometheus/README.md)

### Known problem
