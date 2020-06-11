PROJECT?=pangeo-181919
NAMESPACE?=staging
ZONE?=us-central1-b
CLUSTER?=dev-pangeo-io-cluster
CORE_POOL?=core-pool
JUPYTER_POOL?=jupyter-pool
JUPYTER_POOL_SMALL?=jupyter-pool-small
WORKER_POOL?=dask-pool
SCHEDULER_POOL?=scheduler-pool

# Creation of the Kubernetes Cluster for Google
#
# Notes
# -----
# The pangeo-rbac stuff is untested.
#
# References
# ----------
# https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-provisioning
# https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity

# ----------------------------------------------------------------------------
# Kubernetes Cluster
#
#
# TODO: enable nodepool auto-provisioning
		# --enable-autoprovisioning --min-cpu 1 --min-memory 1 --max-cpu 1000 --max-memory 5200 \
		# --autoprovisioning-service-account=pangeo \

test:
	@echo $(CLUSTER) $(WORKER_POOL)

cluster:
	echo "[Creating core pool in $(ZONE)]"
	gcloud container clusters create $(CLUSTER) \
		--num-nodes=1 \
		--zone=$(ZONE) \
		--cluster-version=latest \
		--no-enable-ip-alias \
		--enable-autoupgrade \
		--machine-type=n1-standard-1 \
		--enable-autoscaling --min-nodes=1 --max-nodes=5 \
		--workload-pool=$(PROJECT).svc.id.goog
	gcloud container clusters get-credentials $(CLUSTER) --zone=$(ZONE)
	kubectl create namespace $(NAMESPACE)
	kubectl -n $(NAMESPACE) apply -f ../pangeo-deploy/templates/pangeo-rbac.yaml
	gcloud iam service-accounts add-iam-policy-binding \
	  --role roles/iam.workloadIdentityUser \
	  --member "serviceAccount:$(PROJECT).svc.id.goog[$(NAMESPACE)/pangeo]" \
	  pangeo@pangeo-181919.iam.gserviceaccount.com
	kubectl annotate serviceaccount \
	  --namespace $(NAMESPACE) \
	   pangeo \
	   iam.gke.io/gcp-service-account=pangeo@$(PROJECT).iam.gserviceaccount.com
	kubectl apply -f https://raw.githubusercontent.com/dask/dask-gateway/0.7.1/resources/helm/dask-gateway/crds/traefik.yaml -n $(NAMESPACE)


serviceaccount:
	gcloud iam service-accounts add-iam-policy-binding \
		--role roles/iam.workloadIdentityUser \
		--member "serviceAccount:$(PROJECT).svc.id.goog[$(NAMESPACE)/pangeo]" \
		pangeo@$(PROJECT).iam.gserviceaccount.com
	kubectl annotate serviceaccount \
	  --namespace $(NAMESPACE) \
		pangeo \
		iam.gke.io/gcp-service-account=pangeo@$(PROJECT).iam.gserviceaccount.com

pangeo:
	helm upgrade --wait --install \
		staging pangeo/pangeo \
		--namespace=$(NAMESPACE) --version=v0.2.2-n059.h1730652 \
		-f values.yaml -f secret.yaml

lifecycle: lifecycle.json
	gsutil lifecycle set $< gs://pangeo-scratch


# ---------------------------------------------------------------------------
# Node Pools
#
core-pool:
	gcloud container node-pools create $(CORE_POOL) \
		--cluster=$(CLUSTER) \
		--workload-metadata=GKE_METADATA \
		--num-nodes=0 \
		--machine-type=n1-standard-2 \
		--zone=$(ZONE) \
		--enable-autoupgrade \
		--enable-autorepair \
		--enable-autoscaling --min-nodes=0 --max-nodes=100 \
    	--node-labels="hub.jupyter.org/nodepurpose=core"

jupyter-pool:
	gcloud container node-pools create $(JUPYTER_POOL) \
		--cluster=$(CLUSTER) \
		--workload-metadata=GKE_METADATA \
		--num-nodes=0 \
		--machine-type=n1-highmem-16 \
		--zone=$(ZONE) \
		--enable-autoupgrade \
		--enable-autorepair \
		--enable-autoscaling --min-nodes=0 --max-nodes=30 \
		--node-labels="hub.jupyter.org/node-purpose=user" \
	    --node-taints hub.jupyter.org_dedicated=user:NoSchedule

jupyter-pool-small:
	gcloud container node-pools create $(JUPYTER_POOL_SMALL) \
		--cluster=$(CLUSTER) \
		--workload-metadata=GKE_METADATA \
		--num-nodes=0 \
		--machine-type=n1-highmem-2 \
		--zone=$(ZONE) \
		--enable-autoupgrade \
		--enable-autorepair \
		--enable-autoscaling --min-nodes=0 --max-nodes=30 \
		--node-labels="hub.jupyter.org/node-purpose=user" \
	    --node-taints hub.jupyter.org_dedicated=user:NoSchedule

jupyter-gpu-pool:
	# I think that GKE automatically adds the GPU taint
	gcloud container node-pools create jupyter-gpu-pool \
		--cluster=$(CLUSTER) \
		--workload-metadata=GKE_METADATA \
		--num-nodes=0 \
		--machine-type=n1-standard-4 \
		--accelerator=type=nvidia-tesla-t4,count=1 \
		--zone=$(ZONE) \
		--enable-autoupgrade \
		--enable-autorepair \
		--enable-autoscaling --min-nodes=0 --max-nodes=4 \
		--node-labels="hub.jupyter.org/node-purpose=user" \
		--node-taints=hub.juptyer.org/dedicated=user:NoSchedule

dask-pool:
	gcloud container node-pools create $(WORKER_POOL) \
		--cluster=$(CLUSTER) \
		--workload-metadata=GKE_METADATA \
		--num-nodes=0 \
		--machine-type=n1-highmem-4 \
		--zone=$(ZONE) \
		--enable-autoupgrade \
		--enable-autorepair \
		--enable-autoscaling --min-nodes=0 --max-nodes=300 \
		--node-labels="k8s.dask.org/node-purpose=worker" \
		--node-taints=k8s.dask.org/dedicated=worker:NoSchedule

scheduler-pool:
	gcloud container node-pools create $(SCHEDULER_POOL) \
		--cluster=$(CLUSTER) \
		--workload-metadata=GKE_METADATA \
		--num-nodes=0 \
		--machine-type=n1-highmem-16 \
		--zone=$(ZONE) \
		--enable-autoupgrade \
		--enable-autorepair \
		--enable-autoscaling --min-nodes=0 --max-nodes=50 \
		--node-taints=k8s.dask.org/dedicated=scheduler:NoSchedule
