# Deploy Dockercoins app

Deploy redis:

```
kubectl create deployment redis --image=redis
```

Deploy everything else:

```
kubectl create deployment hasher --image=dockercoins/hasher:v0.1
kubectl create deployment rng --image=dockercoins/rng:v0.1
kubectl create deployment webui --image=dockercoins/webui:v0.1
kubectl create deployment worker --image=dockercoins/worker:v0.1
```

Expose each deployment, specifying the right port:

```
kubectl expose deployment redis --port 6379
kubectl expose deployment rng --port 80
kubectl expose deployment hasher --port 80
```

Create a NodePort service for the Web UI:

```
kubectl expose deploy/webui --type=NodePort --port=80
```

Check the port that was allocated:

```
kubectl get svc
```

