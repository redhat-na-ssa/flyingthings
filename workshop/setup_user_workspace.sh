#!/bin/bash

# Define the range of users and the GPU quota values
START=1      # Starting user number (user01, user02, etc.)
END=40       # Ending user number (user10, user11, etc.)

# Loop through the range of users
for i in $(seq -f "%02g" $START $END)
do
    USERNAME="user${i}"

    echo "Creating project for ${USERNAME}..."
    
    # Create a new project/namespace for the user
    oc new-project ${USERNAME}

    # Assign admin role to the user for their project
    oc adm policy add-role-to-user admin ${USERNAME} -n ${USERNAME}

done

echo "All users and quotas have been successfully created."
