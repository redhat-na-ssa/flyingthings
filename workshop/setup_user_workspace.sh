#!/bin/bash

# Define the range of users and the GPU quota values
START=1      # Starting user number (user01, user02, etc.)
END=2       # Ending user number (user10, user11, etc.)
GPU_REQUEST="2"   # Requested GPU quota
GPU_LIMIT="2"     # Limit for GPU usage

# Loop through the range of users
for i in $(seq -f "%02g" $START $END)
do
    USERNAME="user${i}"

    echo "Creating project for ${USERNAME}..."
    
    # Create a new project/namespace for the user
    oc new-project ${USERNAME}

    # Assign admin role to the user for their project
    oc adm policy add-role-to-user admin ${USERNAME} -n ${USERNAME}

    # Create a temporary YAML file for the GPU quota
    cat <<EOF > ${USERNAME}_gpu_quota.yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: gpu-quota
spec:
  hard:
    requests.nvidia.com/gpu: "${GPU_REQUEST}"  # Maximum GPUs that can be requested
    limits.nvidia.com/gpu: "${GPU_LIMIT}"      # Maximum GPUs that can be used
EOF

    # Apply the GPU quota to the user's project
    echo "Applying GPU quota for ${USERNAME}..."
    oc apply -f ${USERNAME}_gpu_quota.yaml -n ${USERNAME}

    # Clean up the temporary quota file
    rm ${USERNAME}_gpu_quota.yaml

    echo "Project and quotas set for ${USERNAME}."
done

echo "All users and quotas have been successfully created."

