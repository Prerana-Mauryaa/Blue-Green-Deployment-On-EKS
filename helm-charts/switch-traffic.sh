#!/bin/bash

INGRESS_NAME=$1
CHART_PATH=$2
HELM_RELEASE_NAME=$3  # Helm release name

# Define service names and ports
SERVICE_1_NAME="service-flaskapp-prod"
SERVICE_2_NAME="service-flaskapp-preprod"

# Get the current service being used in the ingress
CURRENT_SERVICE=$(kubectl get ingress $INGRESS_NAME -o=jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}')

# Check which service is currently in use and switch traffic
if [ "$CURRENT_SERVICE" == "$SERVICE_1_NAME" ]; then
  echo "Switching traffic from $SERVICE_1_NAME to $SERVICE_2_NAME"

  # Upgrade Helm chart to switch to the pre-prod service
  helm upgrade $HELM_RELEASE_NAME ${CHART_PATH} \
    --set ingress.services.prod.name=$SERVICE_2_NAME \
    --set ingress.services.qaPreprod.name=$SERVICE_1_NAME
else
  echo "Switching traffic from $SERVICE_2_NAME to $SERVICE_1_NAME"

  # Upgrade Helm chart to switch to the prod service
  helm upgrade $HELM_RELEASE_NAME ${CHART_PATH} \
    --set ingress.services.prod.name=$SERVICE_1_NAME \
    --set ingress.services.qaPreprod.name=$SERVICE_2_NAME
fi

echo "Traffic switch complete."