## Spark on IBM Container Service


reference [Running Spark on K8s](https://apache-spark-on-k8s.github.io/userdocs/running-on-kubernetes.html)


###Verified 

* Kubernetes 1.7.4
* Kafka Chart 0.2.2
* ZK Chart 0.4.2
* Spark 2.2.0, Hadoop 2.7.3, Spark-K8s 0.5.0


### Preparation

Due to a [DNS name not verified against API Server within driver pod issue](https://github.com/apache-spark-on-k8s/spark/issues/558#issuecomment-348671507), need to rebuild images with changes. 

[Prebuild images](https://hub.docker.com/r/yanglei99)

#### Build steps

	# Build Spark first
	build/mvn -DskipTests  package install

	# Build Kubernetes Resource Manager
	build/mvn compile install -Pkubernetes -pl resource-managers/kubernetes/core -am -DskipTests

	# Create distribution
	dev/make-distribution.sh --tgz -Phadoop-2.7 -Pkubernetes
	
	# Build and Push image from generated dist
	cd dist
	./sbin/build-push-docker-images.sh -r docker.io/YOUR_ACCT -t v2.2.0-kubernetes-0.5.0 build
	./sbin/build-push-docker-images.sh -r docker.io/YOUR_ACCT -t v2.2.0-kubernetes-0.5.0 push
	
	
#### Change Details

##### [KubernetesClusterManager]( https://github.com/apache-spark-on-k8s/spark/blob/branch-2.2-kubernetes/resource-managers/kubernetes/core/src/main/scala/org/apache/spark/scheduler/cluster/k8s/KubernetesClusterManager.scala) 

Allow `spark.kubernetes.driverEnv.KUBERNETES_MASTER` to override default `KUBERNETES_MASTER_INTERNAL_URL` when creating KubernetesClient. 

From:

	val kubernetesClient = SparkKubernetesClientFactory.createKubernetesClient(
        KUBERNETES_MASTER_INTERNAL_URL,
        Some(sparkConf.get(KUBERNETES_NAMESPACE)),
        APISERVER_AUTH_DRIVER_MOUNTED_CONF_PREFIX,
        sparkConf,
        Some(new File(Config.KUBERNETES_SERVICE_ACCOUNT_TOKEN_PATH)),
        Some(new File(Config.KUBERNETES_SERVICE_ACCOUNT_CA_CRT_PATH)))

To:

    val kubernetesClient = SparkKubernetesClientFactory.createKubernetesClient(
        sparkConf.get("spark.kubernetes.driverEnv.KUBERNETES_MASTER",
            KUBERNETES_MASTER_INTERNAL_URL),
        Some(sparkConf.get(KUBERNETES_NAMESPACE)),
        APISERVER_AUTH_DRIVER_MOUNTED_CONF_PREFIX,
        sparkConf,
        Some(new File(Config.KUBERNETES_SERVICE_ACCOUNT_TOKEN_PATH)),
        Some(new File(Config.KUBERNETES_SERVICE_ACCOUNT_CA_CRT_PATH)))


##### generated [dist/sbin/build-push-docker-images.sh](build-push-docker-images.sh)

Need to change away from `declare -A path` when running build on OSX.

#### Spark-submit configuration

Add `--conf spark.kubernetes.driverEnv.KUBERNETES_MASTER=<MASTER URL>` to by pass DNS host name not verified issue.


### To verify

#### Simple Example

	# SparkPi
	bin/spark-submit --deploy-mode cluster --class org.apache.spark.examples.SparkPi --master k8s://http://127.0.0.1:8001 --kubernetes-namespace default --conf spark.executor.instances=3 --conf spark.app.name=spark-pi --conf spark.kubernetes.driver.docker.image=YOUR_ACCT/spark-driver:v2.2.0-kubernetes-0.5.0 --conf spark.kubernetes.executor.docker.image=YOUR_ACCT/spark-executor:v2.2.0-kubernetes-0.5.0 --conf spark.kubernetes.driverEnv.KUBERNETES_MASTER=https://spark.kubernetes.executor.docker.image=YOUR_ACCT/spark-executor-py:v2.2.0-kubernetes-0.5.0  --conf spark.kubernetes.driverEnv.KUBERNETES_MASTER=https://MASTER_IP:MASTER_PORT local:///opt/spark/examples/jars/spark-examples_2.11-2.2.0-k8s-0.5.0.jar
	
	# SparkPi in Python
	bin/spark-submit   --deploy-mode cluster   --master k8s://http://localhost:8001   --kubernetes-namespace default   --conf spark.executor.instances=3 --conf spark.app.name=spark-pi   --conf spark.kubernetes.driver.docker.image=YOUR_ACCT/spark-driver-py:v2.2.0-kubernetes-0.5.0   --conf spark.kubernetes.executor.docker.image=YOUR_ACCT/spark-executor-py:v2.2.0-kubernetes-0.5.0  --conf spark.kubernetes.driverEnv.KUBERNETES_MASTER=https://MASTER_IP:MASTER_PORT --jars local:///opt/spark/examples/jars/spark-examples_2.11-2.2.0-k8s-0.5.0.jar local:///opt/spark/examples/src/main/python/pi.py 10

	# SparkPi with resource staging Server
	kubectl create -f conf/kubernetes-resource-staging-server.yaml	
	bin/spark-submit --deploy-mode cluster --class org.apache.spark.examples.SparkPi --master k8s://http://127.0.0.1:8001 --kubernetes-namespace default --conf spark.executor.instances=3 --conf spark.app.name=spark-pi --conf spark.kubernetes.driver.docker.image=YOUR_ACCT/spark-driver:v2.2.0-kubernetes-0.5.0 --conf spark.kubernetes.executor.docker.image=YOUR_ACCT/spark-executor:v2.2.0-kubernetes-0.5.0 --conf spark.kubernetes.initcontainer.docker.image=YOUR_ACCT/spark-init:v2.2.0-kubernetes-0.5.0 --conf spark.kubernetes.driverEnv.KUBERNETES_MASTER=https://MASTER_IP:MASTER_PORT --conf spark.kubernetes.resourceStagingServer.uri=http://YOUR_WORKER_NODE:31000 local:///opt/spark/examples/jars/spark-examples_2.11-2.2.0-k8s-0.5.0.jar
	
	# GroupBy with shuffle service 
	kubectl create -f conf/kubernetes-shuffle-service.yaml
	bin/spark-submit --deploy-mode cluster --class org.apache.spark.examples.GroupByTest --master k8s://http://localhost:8001 --kubernetes-namespace default --conf spark.app.name=group-by-test --conf spark.kubernetes.driver.docker.image=YOUR_ACCT/spark-driver:v2.2.0-kubernetes-0.5.0 --conf spark.kubernetes.executor.docker.image=YOUR_ACCT/spark-executor:v2.2.0-kubernetes-0.5.0 --conf spark.dynamicAllocation.enabled=true --conf spark.shuffle.service.enabled=true --conf spark.kubernetes.shuffle.namespace=default --conf spark.kubernetes.shuffle.labels="app=spark-shuffle-service,spark-version=2.2.0" --conf spark.local.dir=/tmp/spark-local --conf spark.kubernetes.driverEnv.KUBERNETES_MASTER=https://MASTER_IP:MASTER_PORT  local:///opt/spark/examples/jars/spark-examples_2.11-2.2.0-k8s-0.5.0.jar 10 400000 2
	
Note:
* For GroupBy shuffle service, you must offer `spark.local.dir`
	
#### Kafka Streaming Example

reference [kafka chart](../charts/kafka/README.md)
reference [Spark Kafka Streaming](https://spark.apache.org/docs/2.2.0/streaming-kafka-0-8-integration.html)

	bin/spark-submit --deploy-mode cluster --master k8s://http://localhost:8001  --kubernetes-namespace default --conf spark.app.name=myKafkaApp --conf spark.kubernetes.driver.docker.image=YOUR_ACCT/spark-driver-py:v2.2.0-kubernetes-0.5.0 --conf spark.kubernetes.executor.docker.image=YOUR_ACCT/spark-executor-py:v2.2.0-kubernetes-0.5.0 --conf spark.kubernetes.initcontainer.docker.image=YOUR_ACCT/spark-init:v2.2.0-kubernetes-0.5.0 --jars local:///opt/spark/examples/jars/spark-examples_2.11-2.2.0-k8s-0.5.0.jar  --conf spark.kubernetes.driverEnv.KUBERNETES_MASTER=https://MASTER_IP:MASTER_PORT  --packages org.apache.spark:spark-streaming-kafka-0-8_2.11:2.2.0 --conf spark.kubernetes.resourceStagingServer.uri=http://YOUR_WORKER_NODE:31000  local:///opt/spark/examples/src/main/python/streaming/direct_kafka_wordcount.py my-kafka-kafka-headless:9092 mytopic



### Known problem
