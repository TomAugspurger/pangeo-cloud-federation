#!/usr/bin/env bash
kubectl -n staging apply -f pangeo-sa.yaml


gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:pangeo-181919.svc.id.goog[staging/pangeo]" \
  pangeo@pangeo-181919.iam.gserviceaccount.com

kubectl annotate serviceaccount \
  --namespace staging \
   pangeo \
   iam.gke.io/gcp-service-account=pangeo@pangeo-181919.iam.gserviceaccount.com
