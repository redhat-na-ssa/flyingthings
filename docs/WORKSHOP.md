# Workshop

## Workshop Components

![alt text](images/workshopcomponents.png "Workshop Components")

### OpenShift

OpenShift is the foundation of everything we’re using today. Its ability to securely run containerized workloads makes it ideal for our purposes. Since the nature of Data Science is experimentation and many many iterations, its ability to consistently deploy and maintain multiple environments and configurations makes it a great foundation for ML Operations.

### Red Hat OpenShift Pipelines

OpenShift Pipelines is the engine that drives our operation. All of the elements and tasks that make up our workflow have been automated and are managed by Tekton. As it’s a Kubernetes native CI tool, it helps establish workflows that ensure consistent results with the flexibility to extend capabilities at any time.

### Minio

Minio is an S3 compatible open source object storage service we’ll be using to store our artifacts. It's lightweight and easily deployed to Openshift.

### Yolo

Yolo is written in Python so the workshop is mostly coded in Python. We’ll be using Python 3.9 so feel free to poke around in the code for anything useful.

### FastAPI

For basic model serving we’ll be using FastAPI. It’s lightweight and fairly simple to deploy with our model and it has an excellent SWAGGER interface which comes in handy for testing our model and even serving it to other applications and services.

### Label Studio

And finally there’s LabelStudio. LabelStudio is an annotation tool used to label datasets for input into AI/ML system training. We’ll be using it to collect and label our image datasets.

## Workflow

![alt text](images/workshopworkflow.png "Workflow")

### Collect images

Ideally gather many images of all objects we want to detect from different angles and lighting conditions.

### Annotate images

Annotation is the process of identifying objects in an image and drawing bounding boxes around them. Each image could have multiple different or same objects so the more thorough you are in labeling the more accurate your model will predict.

### Export Artifacts

Once annotation is complete, we export the images, annotations, and classes in a format Yolo can use for training. This is stored in our object storage.

### Launch Pipeline

We give our pipeline parameters like the name of our model, where the annotation export is, and what values to use during the training. Once the training is complete the pipeline stores artifacts from the session as well as additional export formats of the model so it can be consumed by a host of other model servers. The artifacts are again stored in our object storage.

### Test Model

Since our model was deployed with a FastAPI application we can easily test it with the swagger interface.

### Capture missed predictions

During the testing portion it is important to test on images that were not part of the dataset. This will reveal any precision issues with the model. Missed or low confidence predictions can be collected and input back into the pipeline.

### Add images to dataset

We can collect all the missed images and add them to LabelStudio where they will now be part of that dataset going forward.

### Repeat

We then annotate, as before, and repeat the process until we have acceptable confidence levels in our predictions.

## The Pipeline

![alt text](images/workshoppipeline.png "Pipeline")

- Fetch repo pulls our git repo code into the pipeline workspace.
- Get Dataset pulls our zip file into the workspace and unzips it.
- Create Classfile picks up the classes.txt file and converts it to a YAML file that can be - consumed by YOLO. This is a template which also identifies the folder structure for the - training.
- If the image resize flag is set, the images will be resized to a maximum width. This module - can be used in the future for other image pre-processing that help improve accuracy.
- Distribute Dataset groups the files into 3 groups. 70% go to training, and the remaining 30% are split beterrn test and validation. The groups are then moved to their respective directories for training. - This grouping is done randomly each run.
- If the GPU flag is set the training requests a node with GPU and runs the actual training on - that node. If GPU is not set, the training is done with CPUs.
- Once training is complete the resulting model is exported to onnx format for consumption by - other model serving solutions.
- Now, all the artifacts from the training including the reports, model, class file, and - exports are written to object storage where they are tagged and propagated to appropriate - folders.
- If the Deploy flag is set, the FastAPI app is deployed with the latest model.
- Finally a summary of the pipeline run is presented with parameter information.

## Getting Started

### Prerequisites

- An OpenShift cluster at version 4.12 or greater.
  - Single Node Openshift with at least 32GB RAM will be adequate
  - GPU Enabled Node (Optional)
  - OCP internal registry
  - OpenShift Pipelines Operator
  - Dynamic Storage Provisioning (ODF, LVM Storage, etc)
  - Cluster Admin
- Workstation with terminal (RHEL or CentOS Streams with bash)
  - Git client
  - Tekton client
- Optional
  - Still camera
  - Webcam

## Building the workshop
For this workshop we'll be interacting with environment through a browser. Once you have logged into your lab environment with the proper credentials, we're going to install the web terminal to facilitate command line interactions.

1. Login to your cluster from your workstation.
2. Install the "Web Terminal" from OperatorHub.
- From the OpenShift Console, expand the "Operators" menu item and click on "OperatorHub"
- Type "Terminal" in the search box on the OperatorHub page.
- Click on "Web Terminal" and click "Install"
- Leave all the defaults and scroll to the bottom and click "Install"
3. Once the terminal has been installed refresh your browser. You should see a new icon near the top right of the screen resembling a command prompt `>_`  Click this button to launch the terminal.
- Note: this will launch a container with ephemeral storage, so try not to close it as it will lose anything downloaded or edited. Fortunately you can easily recover if this happens.

4. Clone the repository to your terminal session.

```
git clone https://github.com/redhat-na-ssa/flyingthings.git
```

5. Go to the directory flyingthings and create the project where you will be deploying the workshop.

```
cd flyingthings
```

6. Run the `bootstrap.sh` script to install and configure cluster components. You may receive errors if this is the first time running the bootstrap. This can be caused due to components not being ready. Simply wait a minute or so and run it again. 
- Note: all scripts must be run from the project root.

```
scripts/bootstrap.sh
```

This will attempt to setup the AWS autoscaler for the GPU nodes. This does two things:

- Reduces the installation to a compact cluster to 1-3 nodes - this helps save on hosting costs.

- Creates a Machineset for the GPU node which is used to provision a GPU when needed and deletes it after a period of idle time. These actions are entirely controlled by the OpenShift autoscaler. If not hosting on AWS you can ignore the message.

Now you can run the main components and pipeline installer. These scripts are idempotent and can be run sequentially so you can launch them from the same command line.

We've also included an initial training for "flyingthings" which produces the first model. While optional, we recommend running it as well as it performs a training and deployment to test that all components and autoscaling have been installed and configured properly. 
- Note: The training will take approximately 6 minutes, but it can take up to 12 minutes for the autoscaler to provision the GPU node. You could provision the node after running the `bootstrap.sh` script by increasing the node count on the gpu machineset from 0 to 1. Once the new node has completed provisioning and operator installations it should be ready for training.

```
scripts/01-setup-pipelines.sh
scripts/02-run-train-model.sh
```

The last script `03-deploy-model-yolo.sh` will deploy the pretrained yolo model which comes in handy to compare against any custom models. Deploy it by running...

```
scripts/03-deploy-model-yolo.sh
```

Let’s take a look at what actually got created and deployed.

In Deployments, we see four apps. LabelStudio, Minio, model-flyingthings and model-yolo.  Let’s start with Minio. We can use the route to connect to the Minio console. The username and password is `minioadmin`.  We can see that there is a bucket already created called `flyingthings`.  In this bucket the main thing to notice is the zip file called `flyingthings-yolo.zip`.  This is the main artifact used in training our custom model. More on that in a bit.

## Launching the deployed apps
Let's take a look at the apps. We do this by navigating to and expanding "Networking" on the left menu and clicking on "Routes". If the project selector at the top of the page is not set to "ml-demo" click and select it from the list.
- First, let's click on `minio-console`. You can login with username and password of `minioadmin`

![alt text](images/minio-flyingthings.png "Minio Bucket")
We'll revisit this when we're ready for re-training, but for now leave this tab open.

We’ll come back to LabelStudio later, but let’s take a look at model-yolo which we deployed earlier. This is useful as a baseline for what yolo can do out of the box and it’s a good introduction for the SWAGGER interface. After clicking on its route you should see the swagger interface.

![alt text](images/fastapi.png "FastAPI")

All of the endpoints are listed here with some basic documentation and the ability to actually send and receive data. This comes in handy as you don’t need to bother with a client that supports POST requests when you need to do simple testing. So let’s do a quick test. 
## Testing the model
1. Expand the Detect function and click `Try It Out` to activate the panel. 
2. Now we can pick an image file to upload and have our model make a prediction. Let’s pick something good.
[![Something Good](https://raw.githubusercontent.com/redhat-na-ssa/flyingthings/main/docs/images/FunCakes-recept-delicious-donuts-website-1-960x720-c-default.jpeg)](![image_url](https://raw.githubusercontent.com/redhat-na-ssa/flyingthings/main/docs/images/FunCakes-recept-delicious-donuts-website-1-960x720-c-default.jpeg) "Download image")
3. Downlad the above image and use the Swagger interface to send it to our model.
4. Perfect! In the output we see our model has predicted 20 donuts in our image. 
5. There’s also an endpoint to show the image marked up with bounding boxes and confidence scores, so let’s try that one. 
- From the output copy the name of the file Navigate to `/uploads/get/image/{fname}` and enter the name from the previous output `FunCakes-recept-delicious-donuts-website-1-1000x750.jpg` 
6. And, yes. We see 20 predictably delicious donuts.

![alt text](images/mmmm-donuts.png "mmmm donuts")

Our pipeline has the option to deploy this same model server for any custom model we create. This will come in handy for the workshop.

## Workshop Use Case 1
Using an existing model is a great way to jumpstart a project as you can use fine tuning or re-training to adapt it to your needs. Let's say we need to detect airplanes and helicopters. We'll see how well the pretrained model does.
1. Go back to our `model-yolo` app. 
2. Download the following images for input. 
- [Download Plane Image](https://raw.githubusercontent.com/redhat-na-ssa/flyingthings/main/docs/images/f16.jpeg)
- [Download Heli Image](https://raw.githubusercontent.com/redhat-na-ssa/flyingthings/main/docs/images/heli01.jpg)
3. Test each of the images with the Swagger interface and see how well it detects each by the confidence score in the bounding box image.

So we see it can detect the airplane fairly well but totally misses the helicopter classification. 

### Overview

We’re going to make a custom model that can detect helicopters and airplanes. For this model, I’ve downloaded hundreds of images of planes and helicopters from Kaggle and already created annotations for the set. You will see it in the `flyingthings-yolo.zip` file in the bucket. Download this file to your workstation.

If we unzip the file you will find the class file and folders containing the images and the labels.

```
flyingthings-yolo $ ls -al
total 92
drwxrwsrwx. 4 user 1000820000  4096 Aug 25 13:43 .
drwxrwsrwx. 3 user 1000820000  4096 Aug 25 13:42 ..
-rw-r--r--. 1 user 1000820000    23 Jun 11 08:00 classes.txt
drwxr-sr-x. 2 user 1000820000 40960 Jun 11 08:00 images
drwxr-sr-x. 2 user 1000820000 36864 Jun 11 08:00 labels
-rw-r--r--. 1 user 1000820000   226 Jun 11 08:00 notes.json
flyingthings-yolo $ 
```

You can see the class file contains the two classes we care about, fixed wing and rotor aircraft. The images folder has over 300 pictures of all kinds of planes and helicopters. The labels folder contains all the labels for the images. In the file is the class id and coordinates of the bounding boxes. As a general rule, the more representations of objects in the dataset the more accurate the predictions. There are exceptions, but you should always try to get the most instances of the cleanest data possible.

Alright, now it’s time to run the pipeline and get our first custom model.

## Launch the pipeline (optional)

We should have already run the training in previous steps. If not we can run it here

```
scripts/02-run-train-model.sh
```

## Re-test our images on the new model
Return to the "Routes" items and launch or new model `model-flyingthings`. We'll see the Swagger interface. Use our previous heli and plane images and see the results.

If all went well we should see dramatic improvement in confidence of the plane AND proper classification of the heli. You should also note that it no longer detects people in the heli image as it is only trained on the two classes.

## Workshop Use Case 2
### Overview
Now that we know that a pretrained model can be adapted for custom classifications, let's introduce a completely new dataset. 
- Our scenareo: detect individual automobiles from a set of HO Scale miniatures.

### How we'll do it
We'll follow a simple classification and training workflow outline above in a step by step process to produce a new custom model.
1. I've already collected images of several vehicles and loaded them into Label Studio. Go back to the "Routes" page and launch it from the apps. Username is "user1@example.com" password is "password1".
2. You should see a single project called "HOScale". Click on the project.
3. You'll see a table with images for annotation. Click on any of the images and you'll see where bounding boxes and labels have been added.
4. On the navigation at the top click back to the HOScale project.
5. In practice, someone would go through each image and draw the boxes for each class detected in all the images. I've already labeled everything to speed this along. Now, we'll just export our images and labels to kick off a training. At the top right click on "Export".
6. In the dialog select "YOLO" format and click "Export"
7. It should download a file named something like "project-xx-at-xxx...". Once downloaded rename the file to `hoscale.zip`
8. Now we'll store the export in a bucket for our training automation to pick it up. From out "Routes" page launch the "minio-console" if not already open.
9. From the "Administrator" menu on the side click "Buckets"
10. Click "Create Bucket" and name it "hoscale". All defaults are fine.
11. Under "User" click "Object Browser" and navigate to your new bucket.
12. Click "Upload File" and select our export "hoscale.zip"

Once the upload is complete we're almost ready to train our custom model.
We just need to make a new training script and we're on our way.

### New training script
1. If you web terminal is still active return to your command prompt, if not you'll need to launch a new one and re-clone the repo.
2. Copy the training script
- ```cp scripts/02-run-train-model.sh scripts/04-run-train-hoscale.sh```
3. Edit the new script.
- ```vi scripts/04-run-train-hoscale.sh```
4. Make the following changes:
```
-p DATASET_ZIP=flyingthings-yolo.zip \ to -p DATASET_ZIP=hoscale.zip \

-p MODEL_NAME=model-flyingthings \ to -p MODEL_NAME=model-hoscale \

-p DEPLOY_ARTIFACTS="Y" \ to -p DEPLOY_ARTIFACTS="N" \

-p MINIO_BUCKET=flyingthings \ to -p MINIO_BUCKET=hoscale \
```
5. Save and run the file. Make sure you're in the right project.
```
oc project ml-demo
scripts/04-run-train-hoscale.sh
```

The output of the job should spool by in the terminal, but you can also monitor it from the console itself. To avoid inadvertlently closing the terminal, 
1. launch a new console by right clicking on the Red Hat Openshift logo in the upper left corner and select "Open link in new tab".
2. Navigate to "Pipelines" and select "Pipelines" You should see a pipeline running with a flodder bar progressing. Click on the bar and you'll see all the tasks progresing with their output logs displayed.

As the job kicks off we can monitor it from the console. Here we see all the training tasks displayed for the pipeline. With GPUs it should take around 5 or 6 minutes to run. CPUs will take significantly longer.

![alt text](images/pipeline-train.png "Training Pipeline")
It will take some time to complete, but when finished you will see the summary and have a new app deployed with your model AND artifacts from the training in your minio bucket.

### Test the new model
1. From our "Routes" you should now see the "model-hoscale" app. Click to launch the Swagger interface.
2. Use images in the "hoscale" folder to test the model.


## Review

Now, let’s review what we’ve done so far.

- Deployed pipeline and supporting tools/images to OpenShift
- Deployed pre-annotated images to object storage for input into pipeline
- Instantiated pipeline to build custom Yolo model where the pipeline:
  - ingested images, labels, and class files
  - preprocessed images by resizing them to a maximum width``
  - distributed images to “train”, “test”, and “valid” groups for Yolo training
  - trained a custom yolo model
  - exported our custom model to “onnx” format
  - saved our model, export, and training artifacts to object storage
  - Deployed our custom model to OpenShift in a containerized FastAPI application
- Validated our custom model by interacting with API endpoints

## Extra Credit
We've only scratched the surface here with our platform capabilities. Usually we will want an application to interact with our model. So, for extra credit, I've created a simple app to interact with our model. 

We'll start with the pretrained model but you can easily adapt it to our custom models.

1. From our terminal go back to the home directory and clone this repo.
```
cd
git clone https://github.com/davwhite/cvbrowser.git
```
2. Build the image.
```cvbrowser/build-is.sh```
3. Edit the deployment for your cluster.
```
  - name: DETECT_URL
    value: "https://model-yolo-ml-demo.apps.<your.cluster.name>/detect"
  - name: GET_IMAGE_URL
    value: "https://model-yolo-ml-demo.apps.<your.cluster.name>/uploads/get/image"
  - name: GET_IMAGES_URL
    value: "https://model-yolo-ml-demo.apps.<your.cluster.name>/uploads/get"
image: >-
          image-registry.openshift-image-registry.svc:5000/ml-demo/cvision-browser:latest
```
4. Deploy the app.
```
oc create -f cvbrowser/deployment_yolo.yaml 
```

Once app has deployed you can find it in "Routes" as "cvbrowser-rt". Just click on it to launch. It's a simple FastAPI app that lets you quickly upload images for object detection and allows you to review previously uploaded detections.

# Wrap Up
This simplified workflow is a demonstration of capabilities of the Kubernetes platform as provided by Red Hat and as such has only scratched the surface of possibilities. The platform makes it possible to deploy industry stand and open source tools to fit the needs of your AI/ML development needs in a way that fits your preferences and scales to meet capacity and expansion. 