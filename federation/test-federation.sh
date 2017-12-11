CLUSTERS="mycluster-1 mycluster-2 mycluster-icp"
for cluster in ${CLUSTERS}; do
  echo ""
  echo "${cluster}"
  kubectl --context=${cluster} get pods
  kubectl --context=${cluster} describe services nginx
done
