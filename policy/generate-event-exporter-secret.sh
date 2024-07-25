# # BYO: 1. create the topics; 2. create the user; 3. create the transport secret 
kafka_user=event-exporter-kafka-user
namespace=multicluster-global-hub

# generate transport secret
bootstrap_server=$(kubectl get kafka kafka -n "$namespace" -o jsonpath='{.status.listeners[1].bootstrapServers}')
kubectl get kafka kafka -n "$namespace" -o jsonpath='{.status.listeners[1].certificates[0]}' > ./kafka-ca-cert.pem
kubectl get secret $kafka_user -n "$namespace" -o jsonpath='{.data.user\.crt}' | base64 -d > ./kafka-client-cert.pem
kubectl get secret $kafka_user -n "$namespace" -o jsonpath='{.data.user\.key}' | base64 -d > ./kafka-client-key.pem

# generate the secret in the target cluster: SECRET_KUBECONFIG, SECRET_NS
kubectl create ns "$SECRET_NS" --dry-run=client -oyaml | kubectl --kubeconfig "$SECRET_KUBECONFIG" apply -f -
kubectl create secret generic acm-event-exporter-secret -n "$SECRET_NS" --kubeconfig "$SECRET_KUBECONFIG" \
    --from-literal=bootstrap.server="$bootstrap_server" \
    --from-literal=event.topic=event \
    --from-file=ca.crt=./kafka-ca-cert.pem \
    --from-file=client.crt=./kafka-client-cert.pem \
    --from-file=client.key=./kafka-client-key.pem 
