#!/bin/bash

# Set namespace and ingress name
INGRESS_NAME=$1

# Define services
SERVICE_1_NAME="service-prod"
SERVICE_1_PORT=80
SERVICE_2_NAME="service-preprod"
SERVICE_2_PORT=80

# Get current service being used in the ingress
CURRENT_SERVICE=$(kubectl get ingress $INGRESS_NAME -o=jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}')

# Check which service is currently in use and switch
if [ "$CURRENT_SERVICE" == "$SERVICE_1_NAME" ]; then
  echo "Switching traffic from $SERVICE_1_NAME to $SERVICE_2_NAME"
  kubectl patch ingress $INGRESS_NAME  \
    -p "{\"spec\":{\"rules\":[{\"host\":\"your-prod-host\",\"http\":{\"paths\":[{\"path\":\"/\",\"pathType\":\"Prefix\",\"backend\":{\"service\":{\"name\":\"$SERVICE_2_NAME\",\"port\":{\"number\":$SERVICE_2_PORT}}}}]}}]}}"
else
  echo "Switching traffic from $SERVICE_2_NAME to $SERVICE_1_NAME"
  kubectl patch ingress $INGRESS_NAME  \
    -p "{\"spec\":{\"rules\":[{\"host\":\"your-prod-host\",\"http\":{\"paths\":[{\"path\":\"/\",\"pathType\":\"Prefix\",\"backend\":{\"service\":{\"name\":\"$SERVICE_1_NAME\",\"port\":{\"number\":$SERVICE_1_PORT}}}}]}}]}}"
fi

echo "Traffic switch complete."
