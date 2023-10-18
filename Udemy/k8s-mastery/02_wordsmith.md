## Let's deploy another application called wordsmith

Wordsmith has 3 components:

a web frontend `bretfisher/wordsmith-web`

an API backend `bretfisher/wordsmith-words`

a postgres DB `bretfisher/wordsmith-db`

These images have been built and pushed to Docker Hub

We want to deploy all 3 components on Kubernetes


Here's how the parts of this app communicate with each other:

The web frontend listens on port 80

The web frontend should be public (available on a high port from outside the cluster)

The web frontend connects to the API at the address http://words:8080

The API backend listens on port 8080

The API connects to the database with the connection string pgsql://db:5432

The database listens on port 5432

Your Assignment is to create the kubectl create commands to make this all work

---

```
kubectl create deployment ws-web --image=bretfisher/wordsmith-web
kubectl create deployment ws-words --image=bretfisher/wordsmith-words
kubectl create deployment ws-db --image=bretfisher/wordsmith-db

kubectl expose deploy/ws-web --type=NodePort --port=80 --target-port=80 --name=wsweb
kubectl expose deploy/ws-words --port=8080 --target-port=8080 --name=words
kubectl expose deploy/ws-db --port=5432 --target-port=5432 --name=db
```

