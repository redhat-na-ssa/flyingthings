# flyingthings
Computer vision demo

# Getting Started

## Namespace
Create the namespace:
`oc new-project flyingthings-standalone`
## Build Images
There are a few images we need to build before proceeding with the next part of the workshop. 
1. First, build the opencv image.
```
cd flyingthings/source
oc new-build --name opencv --strategy docker --binary --context-dir .
oc start-build opencv --from-dir opencv --follow 
```
2. Next, build the yolo image.
```
cd flyingthings/source
oc new-build --name yolo --strategy docker --binary --context-dir .
oc start-build yolo --from-dir yolo --follow
```
3. Next, build the model serving image.
```
cd flyingthings/source
oc new-build --name model-server --strategy docker --binary --context-dir .
oc start-build model-server --from-dir model --follow
```
4. Next, build the training image
```
cd flyingthings/source
oc new-build --name flyingthings-training --strategy docker --binary --context-dir .
oc start-build flyingthings-training --from-dir training --follow
```
## Minio
The Minio server will be used to store our models and datasets as well as help version our artifacts. This should be deployed first.
1. Deploy the minio server. 
``` 
cd flyingthings/standalone
01-deploy-minio.sh
```
 Wait for the container to fully deploy before moving on.

2. Deploy the artifacts to the minio server. 
```
02-deploy-artifacts.sh
```
3. Deploy the notebook pod. 
>If your cluster has GPUs configured run 
```
03-deploy-notebookpod_gpu.sh
```
>otherwise run 
```
03-deploy-notebookpod_nogpu.sh
```
4. Once the notebook pod has been deployed fully run to populate Jupyter with our notebooks. Remember, you can look into the logs on the pod to get the token required to log into the notebook. Begin with the first notebook. All instructions are contained within the notebooks.
```
04-deploy-notebooks.sh
```
 

5. ONLY run `99-cleanup.sh` when you want to tear down the entire workshop, otherwise please leave at least the Minio server as all other activities will use it.


## Pipeline - Training
You can use the training pipeline to kickoff a training run and produce a new model. The pipeline takes arguments to help fine tune the training session and produces output which can be evaluated for improvements to the previous models. 
```
cd flyingthings/source/pipelines
```
1. Deploy the training pipeline.
>If your cluster has GPUs run `oc apply -f 01-training-pipeline_gpu.yaml` 

>otherwise run `oc apply -f 01-training-pipeline_nogpu.yaml`  This will setup the pipeline for training.

2. You can launch the training pipeline from the OpenShift console and observe its run from output window. This will publish a new model as well as a zipped file with the results of the training run.

## Pipeline - Model Serving
Once you have models in Minio you can run the model pipeline to serve the model.
1. `cd flyingthings/source/pipelines`
2. Run `oc apply -f 02-model-serv-pipeline.yaml`
3. This pipeline can be run from the console with parameters, but for ease of use there are two files you can use to launch model servers.

    `run-model-pretrained.sh` - This launches a model server with the pre-trained model. This can be used for baselineing purposes. Only need to run it once.

    `run-model-custom.sh` - This is the main model serving image. It will pull the latest trained model and serve it up for consumption.
4. Once the images are built they can be launched by:

    `cd flyingthings/source`
    
    `oc apply -f deploy-pretrained-model.yaml` for the pre-trained and `oc apply -f deploy-custom-model.yaml` for the custom trained model. Each will have routes associated with it for access. Whenever you run the training pipeline the resulting model will be available to the model server. Simply re-deploy the appropriate server and the new model will be available.

