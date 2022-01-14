# Microservices

It is an architecture style for your app

- loosely coupled
- small team owned
- deployable independently
- Very durable and easy to test
- Organized around business skills

---

## Need for microservices

- improved scalability
    - order processing module can be scaled independently of other modules.
- better fauylt isolation
    - If one of the microservices fails, he others are lekely to continue wortking
- optimized scaling decisions
- localized complexity
- Increased business agaility
    - failure of one microservice affects only that feature
- Increased dev productivity
    - new devs can learn quickly

---

## Containers

### Components

1. Runtime
2. Libraries
3. Code

### VM vs. Containers

| VM      | Container |
| ----------- | ----------- |
| Offers complete isolation from the Host OS and other VMs | Offers lightweight isolation from th host and other containers. |
| Runs a whole OS | Runs the user mode portion of the OS |
| Any OS can be run inside VM | Uses the same OS as the host |
| Can be accessed over a network | Needs virtualizednetwork drivers |
| Deploy individual VM using Hyper-v manager / Windows Admin Center | Deploy individual containers using command line |
| Deploy multiple VM's via Powershell or System Center VM manager | Deploy multiple containers using an orchestrator like Kubernetes |

### Docker Pros

Containerization involves bundling an entire runtime environment into a single package.

- application
- all dependencies
- libraries
- binaries
- config files

Docker allows you to run your project, application or code just like you do on your own machine.

### Use cases of Docker

- Allows to code and deploy your environment and configuration
- Same Docker config can also be used in different environments
- Decouples infra requirements from the app enviroment
- Freedom to run multiple IaaS or PaaS without any extra tweaks is achieved using Docker

- Eachenvironment has minor differences
- DOcker provides consistent environment for application by using code development and deployment pipeline
- Immutable nature of Docker images helps to achieve zero change in app runtime environment.
- Increased dev productivity and capacity.

- As close a s possible to production
- As fast as possible for interactive use
- Use Docker's shared volume to make app code available to the container from the Host OS.

- App Isolation of Docker
- Debugging
    - checkpoint containers, container version, difference between two containers.
- Multi Tenancy - isolated environments can be used for multiple projects
- docker.py 
- Rapid deployment
- SErver consolidation

### Benefits of containerization

- Scalability - container replicas
- Security - process isolation and resource limits
- Loosely Coupled - you can substitute or update one without affecting the others.
- shorter life cycles than VM

# Kubernetes Intro

Google introduced Kubernetes or K8s to manage multiple comtainers.
Kubernetes is a Docker orchestration platform.

- Automating the deployment
- Scheduling and scaling of containerized apps.
- Highly scalable, ope source and has a great community
- Public cloud / On premises
- Kubernetes as a service

**Life of an APP**

- Docker image build
- Deploy on Kubernetes 

**Uses of Kubernetes**

- handles a large number of containers and users
- uses nodes to deploy pods
- Manages resources
- Autohealing ensures that your containers are up and running

- CI / CD features
- environment consistency across dev, staging, prod, etc.
- loosely coupled and predictable infra
- higher density of resource utilization
- constantly checks nodes and containers
