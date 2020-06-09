## Prepare the cluster

0. Enable Cloud IAM Credentials API: https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#enable_on_new_cluster
2. Create new nodepools with workload identity. Migrating existing nodepools failed.

```console
cd gke
make dask-pool WORKER_POOL=dask-pool-2 CLUSTER=dev-pangeo-io-cluster 
make scheduler-pool SCHEDULER_POOL=scheduler-pool-2 CLUSTER=dev-pangeo-io-cluster
make jupyter-pool JUPYTER_POOL=jupyter-pool-2 CLUSTER=dev-pangeo-io-cluster
```

## Create the Bucket

1. Manually create bucket pangeo-scratch (us-central1, regular storage, uniform ACL) through the GCP console

## Create the Service Accounts

1. Create a *google* SA: `gcloud iam service-accounts create gcs-scratch-sa`
2. Add the permissions to the GSA
    * In GCP console, Bucket > Permsissions > Add members
    * Gave `gcs-scratch-sa@pangeo-181919.iam.gserviceaccount.com` ObjectAdmin

Link the service accounts

```
K8S_NAMESPACE=dev-staging
KSA_NAME=pangeo
GSA_NAME=gcs-scratch-sa
GSA_PROJECT=pangeo-181919

gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:cluster_project.svc.id.goog[${K8S_NAMESPACE}/${KSA_NAME}]" \
  ${GSA_NAME}@${GSA_PROJECT}.iam.gserviceaccount.com
```

Annotate the KSA

```
kubectl annotate serviceaccount \
  --namespace ${K8S_NAMESPACE} \
   ${KSA_NAME} \
   iam.gke.io/gcp-service-account=${GSA_NAME}@${GSA_PROJECT}.iam.gserviceaccount.com
```
