# Grafana


**Getting the password**

```bash
kubectl get secret --namespace metrics staging-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

**Manually added data source**


kubectl port-forward --namespace=metrics staging-prometheus-server-5b97dfd7b-h92sx 9090
