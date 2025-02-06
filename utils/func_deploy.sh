#!/bin/bash

#az functionapp deployment source config-zip \
#    --resource-group oym-deploy-sand-rg \
#    --name oym-sand-helloworld-fa \
#    --src functions.zip \
#    --build-remote true \
#    --verbose

#az functionapp deployment source config-zip \
#    --resource-group oym-deploy-sand-rg \
#    --name oym-sand-helloworld-fa \
#    --src functions.zip \
#    --build-remote true \
#    --only-show-errors

#az functionapp deployment source config-zip \
#    --resource-group oym-deploy-sand-rg \
#    --name oym-sand-helloworld-fa \
#    --src functions.zip \
#    --build-remote true \
#    --output table \
#    --verbose

az functionapp deployment source config-zip \
    --resource-group oym-deploy-sand-rg \
    --name oym-sand-helloworld-fa \
    --src functions.zip \
    --build-remote true
