# Docker Architecture

![Docker Architecture](/Simplilearn/self-learning/img/docker-architecture.png)

## Images

- Apps are stored and shipped using Images

## Containers

- Encapsulated enviroments for running apps
- Container is defined by the image
- additional configuration options are provided while starting the container.
- if additional options are not defined, the container will only have access to the resources in the image
- new images can be created using a container's current state.

## Networks

Docker networking is a way to connect all the isolated containers to one another.

### Network Drivers

- Bridge
  - default
- Host
  - eliminates the network barrier between docker containers and docker hosts.
  - used when there is no need for network separation between the host and the container.
- Overlay
  - used when containers are runon multiple docker hosts
  - or when muliple apps combine to form swarm services
- None
  - no networking (Kubernetes?)
- Macvlan
  - direct traffic using MAC addresses

## Storage

- Data Volumes
    - persistent storage
- Volume container
    - hosting a volume in a dedicated container and mounting the volume to other containers.
- Bind mounts

### Storage Plugins

- Allows to link to external storage systems

## Kubernetes and Docker

- Pods run one or more closely related containers
- Pods can be scheduled on multiple nodes for high availability
- Kubernetes + Docker is the most common use case.
- Kubernetes includes Docker centric tools like Kompose. Kompose transforms Docker Comnpose commands and settings for Kubernetes use.
- Docker has it's own integrated Kubernetes distribution.

## Docker Commands

```
docker login --help
docker login -u user
```
---
```
docker ps
docker container ls
docker container ls -q
```
  - Quiet, prints only container id
```
docker container ls -s
```
  - Container size
```
docker container ls -f "status=exited"
```
  - filter output, show exited containers only.
---
Start all containers

```
docker start `docker ps -qa`
```

Stop all containers

```
docker stop `docker ps -q`
```

## Docker Networking

Network Sandbox ?

![Docker Network Sandbox](/Simplilearn/self-learning/img/docker-sandbox.png)

### Endpoints

- Reflects a container's network config such as IP address, MAC address, DNS, etc.
- May have multiple endpoints in a network

docker0 = bridge network

### User defined bridge network

- auto DNS resoltion between the comntainers.
- better isolation
- creates a configurable bridge

```
docker network ls
```
