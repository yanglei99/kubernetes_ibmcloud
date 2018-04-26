### QoS


#### Metrics through Prometheus and Grafana

##### Kafka

[Reference Grafana Chart](https://github.com/kubernetes/charts/tree/master/stable/grafana)

[kafka exporter prometheus yaml](values-kafka.yaml)

[Kafka Dashboard](kafka.json)

	// Prometheus with kafka-exporter configuration
	
	helm install --name prometheus stable/prometheus -f values-kafka.yaml
	
	// Enable Grafana
	
	helm install --name grafana stable/grafana --set server.adminPassword=password
	
		export POD_NAME=$(kubectl get pods --namespace default -l "app=grafana-grafana,component=grafana" -o jsonpath="{.items[0].metadata.name}")
     	kubectl --namespace default port-forward $POD_NAME 3001
     	
     	# UI at: 127.0.0.1:3001
     	
		#Add data source dialog in Grafana of data source for Prometheus with Url as http://prometheus-server.default.svc.cluster.local
	
		#Upload the kafka dashboard
	
### Known Issue and limitation

		