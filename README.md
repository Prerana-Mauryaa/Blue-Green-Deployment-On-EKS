
# Deployment of Two Tier Flask portfolio using Kubernetes

I created my own portfolio website using Flask, which is a framework for building web applications in Python. Then, I dockerized it, which means I put it into a container so it can run consistently across different environments. I uploaded that container image to Docker Hub, a place where people can store and share container images.

After that, I set up a Kubernetes cluster, which is like a powerful manager for running lots of containers at once. I used this cluster to deploy my website, making sure it runs smoothly and can handle lots of visitors at the same time.

To make things even easier to manage, I packaged everything using Helm, which is like a template for Kubernetes applications. This helps me deploy and manage my website more efficiently.

Finally, I deployed my website on Amazon EKS (Elastic Kubernetes Service), which is a service provided by Amazon Web Services (AWS) for running Kubernetes on their cloud platform. This ensures my website is always available and can scale up as needed to handle more traffic.

# Dockerizing My Flask Application
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

# install required packages for system
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
COPY . .

# Specify the command to run your application
CMD ["python", "app.py"]
```
4. Build the Docker Image

```bash
docker build . -t flaskapp
```
5. For communication among containers we need a network among them.
```bash
docker network create twotier
```

6. Run MySQL Docker Container 
 
```bash
sudo docker run -d --name flaskapp  --network=twotier -e MYSQL_HOST=mysql -e MYSQL_USER=admin  -e MYSQL_PASSWORD=admin -e MYSQL_DB=mydb -p 5000:5000 flaskapp:latest
```

7. Run Flask Application Docker Container

```bash
sudo docker run -d --name mysql  --network=twotier -e MYSQL_DATABASE=mydb -e MYSQL_USER=admin -e MYSQL_ROOT_PASSWORD="admin" -p 3360:3360 mysql:5.7
```

8. Run this MySQL Query in mysql container

```bash
CREATE DATABASE IF NOT EXISTS mydb;
```
```bash
USE mydb;
```
```bash
CREATE TABLE messages (fullname VARCHAR(255), emailaddress VARCHAR(255), phonenumber VARCHAR(20), message TEXT );
```
9. Login to DockerHub

```bash
docker login
```
Enter DockerHub Id and Password when prompted

10. Tag the image and push it to DockerHub

```bash
docker tag flaskapp:latest preranamauryaa/portfolioflaskapp
```
```bash
docker push preranamauryaa/portfolioflaskapp
```



# Two Tier Application Deployment on Kubernetes Cluster
## First setup kubernetes kubeadm cluster
Use this official documentation of Kubernetes to setup kubeadm  https://v1-28.docs.kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/

## Setup
We need to run the manifests that we created in K8S manifests directory
#### Run these commands one by one

```bash
kubectl apply -f mysql-deployment.yml
```
```bash
kubectl apply -f mysql-svc.yml
```
```bash
kubectl apply -f mysql-pv.yml
```
```bash
kubectl apply -f mysql-pvc.yml
```
```bash
kubectl apply -f mysql-deployment.yml
```
```bash
kubectl apply -f two-tier-app-deployment.yml
```
```bash
kubectl apply -f two-tier-flask-app-svc.yml
```

This will deploy the flask application on Kubernetes Cluster.

# Packaging Flask Application using Helm
## First Install Helm 
Use this official documentation of Helm to Install Helm  https://helm.sh/docs/intro/install/

## Setup for MySQL
### Creating Helm Chart for MySQL
```bash
helm create mysql-chart
```
Edit the templates for manifests and values.yaml according to our deployment need .

### Packaging  mysql-chart
```bash
helm package mysql-chart
```
### Installing the package
```bash
helm install mysql-chart ./mysql-chart
```
## Setup for Flask App
### Creating Helm Chart for flask app
```bash
helm create flask-chart
```
Edit the templates for manifests and values.yaml according to our deployment need .

### Packaging flask-chart
```bash
helm package flask-chart
```
### Installing the package
```bash
helm install flask-chart ./flask-chart
```

# Two Tier Application Deployment on EKS
# IAM Setup

## Create IAM User "eks-admin" with AdministratorAccess

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

# EC2 Setup

## Create Ubuntu Instance (Region: us-west-2)

1. Launch an EC2 instance that acts as entrypoint with Ubuntu AMI in the desired region.
2. SSH to the instance from your local machine.

## Install AWS CLI v2

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip
unzip awscliv2.zip
sudo ./aws/install -i /usr/local/aws-cli -b /usr/local/bin --update
aws configure
```

##  Setup AWS Access

```bash
aws configure
```
## Install Docker

```bash
sudo apt-get update
sudo apt install docker.io
docker ps
sudo chown $USER /var/run/docker.sock
```
## Install kubectl

```bash
curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin
kubectl version --short --client
```
## Install eksctl

```bash
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version
```

## Setup EKS Cluster

```bash
eksctl create cluster --name two-tier-cluster --region us-east-1 --node-type t2.medium --nodes-min 2 --nodes-max 2
```

## Apply Manifests

To apply Kubernetes manifests, navigate to the directory containing your manifests and execute the following command:

```bash
kubectl apply -f configmap-mysql.yaml -f deployment-mysql.yaml -f secrets-mysql.yaml -f svc-mysql.yaml 
```
```bash
kubectl apply -f two-tier-app-deployment.yaml -f two-tier-app-svc.yaml  
```

```bash
kubectl get all 
```

