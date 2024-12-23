# Blue Green Deployment of Flask portfolio on EKS using Helm Charts
This project implements a Blue-Green deployment strategy to seamlessly deploy a Flask-based portfolio application on Amazon EKS. Using a Jenkins pipeline, the workflow automates code retrieval from GitHub, builds, tags, and Dockerizes the application. The deployment process dynamically switches between Blue and Green environments based on the selected configuration, ensuring zero-downtime updates and smooth application rollouts and rollback.

![Blue Green Deployment](https://github.com/Prerana-Mauryaa/Blue-Green-Deployment-On-EKS/blob/master/Diagrams/before_switching.png)

After Switching the  traffics 
![Blue Green Deployment(after switching)](https://github.com/Prerana-Mauryaa/Blue-Green-Deployment-On-EKS/blob/master/Diagrams/after_switching.png)

## Jenkins Pipeline for Blue Green Deployment using Helm Charts
This pipeline facilitates Blue-Green Deployment with comprehensive features to manage deployments, traffic switching, and rollback seamlessly. It includes the following parameters:

### Parameters:
* __DEPLOY_ENV__: Choose the deployment environment (blue or green).
* __DOCKER_TAG__: Specify the Docker image tag for deployment (default: latest).
* __SWITCH_TRAFFIC__: Toggle to switch traffic between Blue and Green environments.
* __DELETE_PREPROD_RESOURCES__ : Remove pre-production resources after deployment.
* __ROLLBACK__: Roll back to the previous environment if needed.
### Key Stages:
* __Build and Push Docker Image__: Builds and pushes the Docker image to Docker Hub.
* __Install MySQL__: Deploys or upgrades the MySQL Helm chart.
* __Install Flask App__: Deploys the Flask app to the chosen environment (blue or green) using Helm.
* __Switch Traffic__: Redirects traffic between Blue and Green environments using a script.
* __Delete Pre-Prod Resources__: Uninstalls resources of the inactive environment after successful deployment.
* __Rollback__: Reverts traffic to the previous environment in case of a failure.

This pipeline is a complete solution for managing Blue-Green deployments with Kubernetes and Helm, ensuring seamless traffic transitions, resource cleanup, and rollback capabilities.

![Jenkins-pipeline](https://github.com/Prerana-Mauryaa/Blue-Green-Deployment-On-EKS/blob/master/Diagrams/Jenkins-pipeline.png)

## Dockerizing the Flaskapp 
## Prerequisites
- Docker
You can install docker by running this command
```bash
  sudo apt update && sudo apt install docker.io
```
## Setup 
1. Create a directory for our flask applications

```bash
  mkdir two-tier-flask-app
  cd two-tier-flask-app
```
2. Put the required files and folders of flask app  into the folder which include app.py, static, templates, requirements.txt .

3. Create a Dockerfile

```bash
vi Dockerfile
```

```Dockerfile
# Use an official Python runtime as the base image
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

# Install required packages for the system
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y gcc default-libmysqlclient-dev pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Copy the requirements file into the container
COPY requirements.txt .

# Install app dependencies
RUN pip install mysqlclient
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY Flask-portfolio/ /app/

# Specify the command to run your application
CMD ["python", "/app/app.py"]
```
4. Build the Docker Image

```bash
docker build . -t flaskapp
```
5. For communication among containers we need a network among them.
```bash
docker network create twotier
```
6. Login to DockerHub

```bash
docker login
```
Enter DockerHub Id and Password when prompted

7. Tag the image and push it to DockerHub

```bash
docker tag flaskapp:latest preranamauryaa/portfolioflaskapp
```
```bash
docker push preranamauryaa/portfolioflaskapp
```

## Packaging Flask Application using Helm
### First Install Helm 
Use this official documentation of Helm to Install Helm  https://helm.sh/docs/intro/install/

This project uses three separate Helm charts to manage different components, ensuring modularity and ease of management:

* __MySQL Helm Chart__: Handles the deployment and configuration of the MySQL database.
* __Flask App Helm Chart__: Manages the deployment of the Flask application.
* __Service and Ingress Helm Chart__: Manages the services and ingress resources for routing traffic to the Flask application.
### Helm Charts Structure
mysql
```
helm-charts/
└── mysql/
    ├── templates/
    |     ├── _helpers.tpl
    |     ├── configmap.yaml
    |     ├── deployment-mysql.yaml
    |     ├── secret-mysql.yaml
    |     ├── svc-mysql.yaml
    ├── Chart.yaml
    └── values.yaml  
```

flask-app
```
helm-charts/
└── flask-app/
    ├── templates/
    |     ├── _helpers.tpl
    |     ├── deployment-flask.yaml
    |     ├── mysql-secrets.yaml
    ├── Chart.yaml
    ├── green-values.yaml
    └── blue-values.yaml  
```

Service
```
helm-charts/
└── Service/
    ├── templates/
    |     ├── _helpers.tpl
    |     ├── ingress.yaml
    |     ├── pre-prod-svc.yaml
    |     ├── prod-svc.yaml
    ├── Chart.yaml
    └── values.yaml  
```

## EKS Setup

### Create IAM User "eks-admin" with AdministratorAccess

1. Navigate to AWS IAM console.
2. Click on "Users" from the sidebar menu.
3. Click on "Add user".
4. Enter "eks-admin" as the username.
5. Select "Attach existing policies directly".
6. Search for "AdministratorAccess" policy and select it.
7. Click on "Next: Tags" and optionally add any tags.
8. Click on "Next: Review".
9. Review the details and click on "Create user".
10. Note down the Access Key ID and Secret Access Key for later use.

### EC2 Setup

#### Create Ubuntu Instance (Region: us-west-2)

1. Launch an EC2 instance that acts as entrypoint with Ubuntu AMI in the desired region.
2. SSH to the instance from your local machine.

### Install AWS CLI v2

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip
unzip awscliv2.zip
sudo ./aws/install -i /usr/local/aws-cli -b /usr/local/bin --update
aws configure
```

###  Setup AWS Access

```bash
aws configure
```
### Install Docker

```bash
sudo apt-get update
sudo apt install docker.io
docker ps
sudo chown $USER /var/run/docker.sock
```
### Install kubectl

```bash
curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin
kubectl version --short --client
```
### Install eksctl

```bash
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version
```

### Setup EKS Cluster

```bash
eksctl create cluster --name Blue-Green --region us-east-1 --node-type t2.medium --nodes-min 2 --nodes-max 2
```

## Setting Up Jenkins with Essential Permissions for Integration
### Installing Jenkins
Use the official documentation of jenkins to install on the ubuntu.
https://www.jenkins.io/doc/book/installing/linux/

After the setup visit https://<public ip>:8080 to get your jenkins server and then complete the profile as guided.

### Add Required Credentials

#### 1. Navigate to the Credentials Section
- Go to **Manage Jenkins > Credentials** from the Jenkins menu.
- Select the appropriate credentials store (e.g., **Global**).

#### 2. Add GitHub Credentials (SSH Key)
- Click **Add Credentials**.
- Select **SSH Username with Private Key** as the kind of credential.
- Fill in the following fields:
  - **Username**: Enter your GitHub username or `git`.
  - **Private Key**: Paste the private SSH key for your GitHub account.
- Save the credentials.

#### 3. Add Docker Hub Credentials (Username and Password)
- Click **Add Credentials** again.
- Select **Username with Password** as the kind of credential.
- Fill in the following fields:
  - **Username**: Enter your Docker Hub username.
  - **Password**: Enter your Docker Hub password.
- Save the credentials.

### Giving Essential Permissions for Integration
#### Give jenkins user docker Permissions
```
sudo usermod -aG docker Jenkins
```
#### Update Kubeconfig  file
```
aws eks update-kubeconfig --region us-east-1 --name Blue-Green
```

### Create a Jenkins Pipeline
Create a Jenkins Pipeline **Blue-Green-Deployemnt** using the pipeline script "Blue-Green-deploy-jenkinsfile" and bluild using parameters.

![pipeline-stage-view](https://github.com/Prerana-Mauryaa/Blue-Green-Deployment-On-EKS/blob/master/ScreenShots/Jenkins-stage-view.png)

## How Switching of traffic is happening 
1. The script switch-traffic.sh first checks the current service receiving traffic by querying the ingress resource:

```
CURRENT_SERVICE=$(kubectl get ingress $INGRESS_NAME -o=jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}')
```
This retrieves the backend service currently mapped to the ingress.

2. Based on the current service:

* If the production service is active (service-flaskapp-prod), the script switches traffic to the pre-production service (service-flaskapp-preprod).
* If the pre-production service is active, it switches back to the production service.
3. The traffic switch is implemented using a Helm upgrade command:

* The --set flags dynamically update the values for ingress.services.prod.name and ingress.services.qaPreprod.name in the Helm chart.



### Note
### Why are we using helm upgrade instead of kubectl patch to switch traffic.
We use helm upgrade instead of kubectl patch because it ensures changes are consistent with the Helm chart, tracks revisions for easy rollbacks, and supports templated updates, making it ideal for CI/CD automation and avoiding configuration drift.

### Images
#### prod-flaskapp.us.to
![Prod](https://github.com/Prerana-Mauryaa/Blue-Green-Deployment-On-EKS/blob/master/ScreenShots/green-flask-app.png)


#### qapreprod-flaskapp.us.to
![Pre Prod](https://github.com/Prerana-Mauryaa/Blue-Green-Deployment-On-EKS/blob/master/ScreenShots/Blue-flask-app.png)


## Rules for next Deployment 
![Rules for next deployment](https://github.com/Prerana-Mauryaa/Blue-Green-Deployment-On-EKS/blob/master/Diagrams/Process.png)

