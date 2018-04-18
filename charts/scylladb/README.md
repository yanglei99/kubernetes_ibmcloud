# ScyllaDB
A ScyllaDB Chart for Kubernetes

[Revised from Cassandra Chart](https://github.com/kubernetes/charts/tree/master/incubator/cassandra) and [ScyllaDB Kuberentes Sample](https://github.com/scylladb/scylla-code-samples/tree/master/kubernetes-scylla)

## Install Chart
To install the ScyllaDB Chart into your Kubernetes cluster (This Chart requires persistent volume by default, you may need to create a storage class before install chart. To create storage class, see `Persist data` section)

```bash
helm install --namespace "scylladb" -n "scylladb" .
```

After installation succeeds, you can get a status of Chart

```bash
helm status "scylladb"
```

If you want to delete your Chart, use this command
```bash
helm delete  --purge "scylladb"
```

## Persist data
You need to have `StorageClass` before able to persist data in persistent volume. 

Some platforms, like IBM Container Service, have predefine StorageClass.
To list current storageclass, run the following

```bash
kubectl get storageclasses
```

To create a `StorageClass` on Google Cloud, run the following

```bash
kubectl create -f sample/create-storage-gce.yaml
```

Then set the following values in `values.yaml`

```yaml
persistence:
  enabled: true
```

If you want to create a `StorageClass` on other platform, please see documentation here [https://kubernetes.io/docs/user-guide/persistent-volumes/](https://kubernetes.io/docs/user-guide/persistent-volumes/)


## Install Chart with specific cluster size
By default, this Chart will create a scylladb with 3 nodes. If you want to change the cluster size during installation, you can use `--set config.cluster_size={value}` argument. Or edit `values.yaml`

For example:
Set cluster size to 5

```bash
helm install --namespace "scylladb" -n "scylladb" --set config.cluster_size=5 .
```

## Install Chart with specific resource size
By default, this Chart will create a scylladb with CPU 2 vCPU and 4Gi of memory.
To update the settings, edit `values.yaml`

## Install Chart with specific node
Sometime you may need to deploy your scylladb to specific nodes to allocate resources. You can use node selector by edit `nodes.enabled=true` in `values.yaml`
For example, you have 6 vms in node pools and you want to deploy scylladb to node which labeled as `cloud.google.com/gke-nodepool: pool-db`

Set the following values in `values.yaml`

```yaml
nodes:
  enabled: true
  selector:
    nodeSelector:
      cloud.google.com/gke-nodepool: pool-db
```

## Configuration

The following tables lists the configurable parameters of the Cassandra chart and their default values.

| Parameter                  | Description                                     | Default                                                    |
| -----------------------    | ---------------------------------------------   | ---------------------------------------------------------- |
| `image.repo`               | `scylladb` image repository                    | `scylladb`                                                  |
| `image.tag`                | `scylladb` image tag                           | `latest`                                                    |
| `image.pullPolicy`         | Image pull policy                               | `Always` if `imageTag` is `latest`, else `IfNotPresent`    |
| `image.pullSecrets`        | Image pull secrets                              | `nil`                                                      |
| `config.cluster_name`      | The name of the cluster.                        | `scylladb`                                                 |
| `config.cluster_size`      | The nubmer of nodes in the cluster.             | `3`                                                        |
| `config.seed_size`         | The number of seed nodes used to bootstrap new clients joining the cluster.                  | `2`           |
| `persistence.enabled`      | Use a PVC to persist data                       | `true`                                                     |
| `persistence.storageClass` | Storage class of backing PVC                    | `default`                                                  |
| `persistence.accessMode`   | Use volume as ReadOnly or ReadWrite             | `ReadWriteOnce`                                            |
| `persistence.size`         | Size of data volume                             | `10Gi`                                                     |
| `resources`                | CPU/Memory and other resource requests/limits   | Memory: `4Gi`, CPU: `2`                                    |
| `service.type`             | k8s service type exposing ports, e.g. `NodePort`| `ClusterIP`                                                |

## Scale ScyllaDB
When you want to change the cluster size of your scylladb, you can use the helm upgrade command.

```bash
helm upgrade --set config.cluster_size=5 scylladb .
```

## Get ScyllaDB status
You can get your ScyllaDB cluster status by running the command

```bash
kubectl exec -it --namespace scylladb $(kubectl get pods --namespace scylladb -l app=scylladb-scylladb -o jsonpath='{.items[0].metadata.name}') nodetool status
```

Output
```bash
Datacenter: datacenter1
=======================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address       Load       Tokens       Owns (effective)  Host ID                               Rack
UN  172.30.85.79  1.24 MB    256          66.7%             1255f18a-1a1f-4c57-bc54-2b59e68ac7dd  rack1
UN  172.30.58.71  838.88 KB  256          66.9%             78c8ec63-298e-430e-9896-2006a83c3588  rack1
UN  172.30.252.4  1.05 MB    256          66.4%             821265e5-c795-4968-84a1-255b1b8512d4  rack1
```

## Connect using cqlsh

```bash
kubectl exec -it --namespace scylladb  $(kubectl get pods --namespace scylladb -l app=scylladb-scylladb -o jsonpath='{.items[0].metadata.name}') cqlsh
```

## Benchmark

You can use [cassandra-stress](https://docs.datastax.com/en/cassandra/3.0/cassandra/tools/toolsCStress.html) tool to run the benchmark on the cluster by the following command

```bash

kubectl exec -it --namespace scylladb $(kubectl get pods --namespace scylladb -l app=scylladb-scylladb -o jsonpath='{.items[0].metadata.name}') -- cassandra-stress write n=10000 -node scylladb-scylladb-1.scylladb-scylladb.scylladb.svc.cluster.local

kubectl exec -it --namespace scylladb $(kubectl get pods --namespace scylladb -l app=scylladb-scylladb -o jsonpath='{.items[0].metadata.name}') -- cassandra-stress read n=1000 -node scylladb-scylladb-1.scylladb-scylladb.scylladb.svc.cluster.local
```


### Known Issue

* Only ClusterIP service type works as seed depends on pod DNS name which is only available for headless service. While [NodePort and LoadBalancer do not support headless service](https://github.com/kubernetes/kubernetes/pull/30932)
* ScyllaDB instance in POD listens to `POD_IP`. So `port-forward` does not work. For cassandra-stress, use `-node scylladb-scylladb-0.scylladb-scylladb.scylladb.svc.cluster.local` to work around the issue, or you can get the `POD_IP` and use it directly
* When "developermode=0", pod may crash
