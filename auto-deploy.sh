#!/bin/bash

terraform apply -var-file="secrets.tfvars" --auto-approve

# Remove the host mappings
ssh-keygen -R k3s-master-1.local
ssh-keygen -R k3s-master-2.local
ssh-keygen -R k3s-master-3.local
ssh-keygen -R k3s-worker-1.local
ssh-keygen -R k3s-worker-2.local