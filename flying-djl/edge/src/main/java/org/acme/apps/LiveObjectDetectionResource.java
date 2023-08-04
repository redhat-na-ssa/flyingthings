package org.acme.apps;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Base64;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import jakarta.enterprise.context.ApplicationScoped;
import javax.imageio.ImageIO;
import jakarta.inject.Inject;
import jakarta.ws.rs.core.Response;
import io.opentelemetry.api.internal.StringUtils;
import io.quarkus.arc.lookup.LookupIfProperty;
import io.quarkus.scheduler.Scheduled;
import io.quarkus.vertx.ConsumeEvent;
import io.smallrye.mutiny.Multi;
import io.smallrye.mutiny.Uni;
import io.smallrye.mutiny.subscription.Cancellable;
import io.vertx.mutiny.core.eventbus.EventBus;

import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import org.acme.AppUtils;
import org.acme.apps.s3.S3ModelLifecycle;
import org.acme.apps.s3.S3Notification;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.jboss.logging.Logger;
import org.opencv.core.Mat;
import org.opencv.imgproc.Imgproc;
import org.opencv.videoio.VideoCapture;
import org.opencv.videoio.Videoio;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonMappingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;

import nu.pattern.OpenCV;

import ai.djl.inference.Predictor;
import ai.djl.modality.Classifications;
import ai.djl.modality.cv.Image;
import ai.djl.modality.cv.ImageFactory;
import ai.djl.modality.cv.output.BoundingBox;
import ai.djl.modality.cv.output.DetectedObjects;
import ai.djl.modality.cv.output.Rectangle;
import ai.djl.modality.cv.translator.YoloV5TranslatorFactory;
import ai.djl.repository.zoo.Criteria;
import ai.djl.repository.zoo.ZooModel;
import ai.djl.training.util.ProgressBar;
import java.awt.image.BufferedImage;

import com.sun.security.auth.module.UnixSystem;


@LookupIfProperty(name = "org.acme.djl.resource", stringValue = "LiveObjectDetectionResource")
@ApplicationScoped
public class LiveObjectDetectionResource extends BaseResource implements ILiveObjectDetection {

    private static final String PATTERN_FORMAT = "yyyy.MM.dd HH:mm:ss";
    private static final String NO_TEST_FILE="NO_TEST_FILE";

    private static Logger log = Logger.getLogger("LiveObjectDetectionResource");

    AtomicInteger schedulerCount = new AtomicInteger();

    @ConfigProperty(name = "org.acme.objecdetection.image.directory", defaultValue="/tmp/org.acme.objectdetection")
    String oDetectionDirString;

    @ConfigProperty(name = "org.acme.objectdetection.video.capture.device.id", defaultValue = "-1")
    int videoCaptureDevice;

    @ConfigProperty(name = "org.acme.objectdetection.test.video.file", defaultValue = NO_TEST_FILE)
    String testVideoFile;

    @ConfigProperty(name = "org.acme.objectdetection.write.unadultered.image.to.disk", defaultValue = "True")
    boolean writeUnAdulateredImageToDisk;

    @ConfigProperty(name = "org.acme.objectdetection.write.modified.image.to.disk", defaultValue = "True")
    boolean writeModifiedImageToDisk;

    @ConfigProperty(name = "org.acme.objectdetection.prediction.change.threshold", defaultValue = "0.1")
    double predictionThreshold;

    @ConfigProperty(name = "org.acme.objectdetection.video.capture.interval.millis", defaultValue = "50")
    int videoCaptureIntevalMillis;

    @ConfigProperty(name = "org.acme.djl.model.zip.path")
    String modelZipPath;

    @ConfigProperty(name = "org.acme.djl.model.zip.name")
    String modelZipName;

    @ConfigProperty(name = "org.acme.djl.model.artifact.name", defaultValue = AppUtils.NA)
    String modelName;

    @ConfigProperty(name = "org.acme.djl.model.synset.name", defaultValue = "synset.txt")
    String synsetFileName;

    @ConfigProperty(name = "org.acme.objectdetection.correction.candidate.best.probability.threshold", defaultValue = "0.80")
    double correctionCandidateBestProbabilityThreshold;

    @ConfigProperty(name = "org.acme.objectdetection.correction.candidate.minimum.probability.threshold", defaultValue = "0.50")
    double correctionCandidateMinimumProbabilityThreshold;

    @ConfigProperty(name = "org.acme.objectdetection.correction.candidate.minimum.detections", defaultValue = "1")
    int correctionCandidateMinimumDetections;

    @ConfigProperty(name = "org.acme.objectdetection.correction.candidate.maximum.detections", defaultValue = "10")
    int correctionCandidateMaximumDetections;

    @ConfigProperty(name = "org.acme.objectdetection.include.prediction.dump.in.corrections.message", defaultValue = "True")
    boolean includePredictionDumpInCorrectionsMessage;

    @Inject
    CriteriaFilter cFilters;

    @Inject
    EventBus bus;

    @Inject
    S3ModelLifecycle s3ModelLifecycle;

    @Inject
    ModelStorageLifecycle modelSL;

    ZooModel<Image, DetectedObjects> model;
    File rawAndBoxedImageFileDir;
    VideoCapture vCapture = null;
    private VideoCapturePayload previousCapture;
    DateTimeFormatter formatter = DateTimeFormatter.ofPattern(PATTERN_FORMAT).withZone(ZoneId.systemDefault());
    Cancellable multiCancellable = null;
    Multi<Long> vCaptureStreamer = null;

    /* The Mat class of OpenCV library is used to store the values of an image.
     * It represents an n-dimensional array and is used to store image data of grayscale or color images, voxel volumes, vector fields, tensors, histograms, etc
     * 
     * Reference:
     *   https://www.tutorialspoint.com/opencv/opencv_storing_images.htm            :   OpenCV - Storing Images
     */
    Mat unboxedMat = null;

    @PostConstruct
    public void startResource() {
        
        super.start();
        try {

            // 1)  Ensure that app can write captured images to file system
            rawAndBoxedImageFileDir = new File(oDetectionDirString);
            if(!rawAndBoxedImageFileDir.exists())
            rawAndBoxedImageFileDir.mkdirs();
            if(!(rawAndBoxedImageFileDir).canWrite())
                throw new RuntimeException("Can not write in the following directory: "+rawAndBoxedImageFileDir.getAbsolutePath());

            
            // 2) Enable web cam  (but don't start capturing images and executing object detection predictions on those images just yet)
            refreshVideoCapture();

            // 3) Instantiate a single OpenCV Mat class to store raw image data
            unboxedMat = new Mat();

            // 4)  Load model and unzip
            loadModel(this.modelZipPath, this.modelZipName);

            // 5)  Populate List of classes so as to assist with identifying models that need correction
            modelSL.unzipModelAndRefreshModelClassList();

            // 6)  Keep pace with video buffer by reading frames from it at a configurable number of millis
            //     On a different thread, this app will periodically evaluate the latest captured frame at that instant in time
            refreshVideoCaptureStreamer();

        }catch(RuntimeException x) {
            throw x;
        }catch(Throwable x){
            throw new RuntimeException(x);
        }finally {
            
        }
    }

    private void refreshVideoCaptureStreamer() {
        if(multiCancellable != null){
            multiCancellable.cancel();
            multiCancellable = null;
            vCaptureStreamer = null;
        }

        vCaptureStreamer = Multi.createFrom().ticks().every((Duration.ofMillis(videoCaptureIntevalMillis))).onCancellation().invoke( () -> {
                log.info("just cancelled video capture streamer");
        });
        continueToPredict = true;
        multiCancellable = vCaptureStreamer.subscribe().with( (i) -> {
            if(vCapture != null)
                vCapture.read(unboxedMat);
        });
    }

    private void loadModel(String newModelZipPath, String newModelZipName) {

        String existingModelFilePath = this.modelZipPath+"/"+this.modelZipName;
        String newModelFilePath = newModelZipPath+"/"+newModelZipName;
        log.infov("loadModel() {0}", newModelFilePath);
        try { 
            Criteria<Image, DetectedObjects> criteria = Criteria.builder()
                .setTypes(Image.class, DetectedObjects.class) // defines input and output data type
                .optModelUrls(newModelFilePath)
                .optModelName(this.modelName)
                .optEngine("OnnxRuntime")  // Specify OnnX explicitly because classpath also includes pytorch
                .optTranslatorFactory(new YoloV5TranslatorFactory())
                .optProgress(new ProgressBar())
                .optArgument("synsetFileName", this.synsetFileName)
                .optArgument("optApplyRatio", true)  // post process
                .optArgument("rescale", true) // post process
                .build();

            ZooModel<Image, DetectedObjects> newModel = criteria.loadModel();

            testModel(newModel);

            this.model = newModel;
            this.modelZipPath = newModelZipPath;
            this.modelZipName = newModelZipName;

        } catch (Exception e) {
            e.printStackTrace();
            if(this.model != null){
                log.errorv("loadModel() Error occurred when loading new model at: {0} . Subsequently, will stick with previously working model at {1}", newModelFilePath, existingModelFilePath);
            }else {
                log.errorv("loadModel() Error attempting to load model at {0}", newModelFilePath);
                throw new RuntimeException(e.getMessage());
            }
        }finally {
        }
    }

    // Evaluate raw video device snapshots at periodic intervals
    @Scheduled(every = "{org.acme.objectdetection.delay.between.evaluation.seconds}" , delayed = "{org.acme.objectdetection.initial.capture.delay.seconds}", delayUnit = TimeUnit.SECONDS)
    void scheduledCapture() {
        
        if (continueToPredict && !unboxedMat.empty()) {
            Instant startCaptureTime = Instant.now();

            Mat matCopy = unboxedMat.clone();

            VideoCapturePayload cPayload = new VideoCapturePayload();
            int captureCount = schedulerCount.incrementAndGet();
            cPayload.setCaptureCount(captureCount);
            cPayload.setStartCaptureTime(startCaptureTime);
            cPayload.setMat(matCopy);

            bus.publish(AppUtils.CAPTURED_IMAGE, cPayload);
        }
    }

    private void testModel(ZooModel<Image, DetectedObjects> newModel){

    }

    // Consume raw video snapshots and apply prediction analysis
    @ConsumeEvent(AppUtils.CAPTURED_IMAGE)
    public void processCapturedEvent(VideoCapturePayload capturePayload){

        if(this.model == null){
            log.debug("processCapturedEvent() model == null, will not attempt to predict");
            return;
        }

        Instant startCaptureTime = capturePayload.getStartCaptureTime();
        int captureCount = capturePayload.getCaptureCount();
        Predictor<Image, DetectedObjects> predictor = null;
        
        try{

            // Determine presence of objects from raw video snapshot
            ImageFactory factory = ImageFactory.getInstance();
            Mat unboxedMat = capturePayload.getMat();
            Image img = factory.fromImage(unboxedMat);

            predictor = model.newPredictor();
            DetectedObjects detections = predictor.predict(img);
            log.infov("{0}", detections);
            capturePayload.setDetectionCount(detections.getNumberOfObjects());
           
            try {
                Classifications.Classification dClass = detections.best();
                List<Double> probabilities = detections.getProbabilities();
                capturePayload.setProbabilities(probabilities);
                capturePayload.setDetectedObjectClassification(dClass.getClassName());
                capturePayload.setDetected_object_probability(dClass.getProbability());

                // Determine whether this VideoCapture is a candidate to correct the model and/or there is a state change
                boolean isCorrectionCandidate = correctionCandidate(capturePayload);
                boolean isDifferent = isDifferent(capturePayload);
                
                // generate an event
                if(isCorrectionCandidate || isDifferent){
                    ObjectMapper oMapper = super.getObjectMapper();
                    ObjectNode rNode = oMapper.createObjectNode();

                    if(isCorrectionCandidate){
                        String correctionReasons = capturePayload.getCorrectionCandidateReasonList().toString();
                        rNode.put(AppUtils.CORRECTION_REASONS, correctionReasons);
                        if(includePredictionDumpInCorrectionsMessage){
                            JsonNode detectionsJSON = oMapper.readTree(detections.toJson());
                            rNode.set(AppUtils.DETECTION_PROBABILITIES, detectionsJSON);
                        }
                        log.warnv("correction candidate! reasons = {0}", correctionReasons);
                    }

                    rNode.put(AppUtils.ID, capturePayload.getStartCaptureTime().getEpochSecond());
                    rNode.put(AppUtils.DEVICE_ID, System.getenv(AppUtils.HOSTNAME));
                    rNode.put(AppUtils.CAPTURE_COUNT, captureCount);
                    rNode.put(AppUtils.CAPTURE_TIMESTAMP, formatter.format(startCaptureTime));

                    if(writeUnAdulateredImageToDisk){
                        // Write un-boxed image to local file system
                        File uBoxedImageFile = new File(rawAndBoxedImageFileDir,  "unAdulteredImage-"+startCaptureTime.getEpochSecond() +".png");
                        BufferedImage uBoxedImage = toBufferedImage(unboxedMat);
                        ImageIO.write(uBoxedImage, "png", uBoxedImageFile);
                        rNode.put(AppUtils.UNADULTERED_IMAGE_FILE_PATH, uBoxedImageFile.getAbsolutePath());
                    }

                    rNode.put(AppUtils.DETECTION_COUNT, capturePayload.getDetectionCount());
                    rNode.put(AppUtils.BEST_OBJECT_CLASSIFICATION, capturePayload.getDetectedObjectClassification());
                    rNode.put(AppUtils.BEST_OBJECT_PROBABILITY, capturePayload.getDetected_object_probability());
                    
                    // Annotate video capture image w/ any detected objects
                    img.drawBoundingBoxes(detections);
                    //drawBoundingBoxWithCustomizedDetections(img, detections);

                     // Encode binary image to Base64 string and add to payload
                    Mat boxedImage = (Mat)img.getWrappedImage();
                    BufferedImage bBoxedImage = toBufferedImage(boxedImage);
                    ByteArrayOutputStream baos = new ByteArrayOutputStream();
                    ImageIO.write(bBoxedImage, "png", baos);
                    byte[] bytes = baos.toByteArray();
                    String stringEncodedImage = Base64.getEncoder().encodeToString(bytes);
                    rNode.put(AppUtils.BASE64_DETECTED_IMAGE, stringEncodedImage);
                    
                    if(writeModifiedImageToDisk) {
                        File boxedImageFile = new File(rawAndBoxedImageFileDir,  "boxedImage-"+ startCaptureTime.getEpochSecond()+".png");
                        ImageIO.write(bBoxedImage, "png", boxedImageFile);
                        rNode.put(AppUtils.DETECTED_IMAGE_FILE_PATH, boxedImageFile.getAbsolutePath());
                    }

                    bus.publish(AppUtils.LIVE_OBJECT_DETECTION, rNode.toPrettyString());

                    this.previousCapture = capturePayload;
                }else {
                    log.debug("not a correction candidate nor is there a state change");
                }
            }catch(NoSuchElementException x) {
                log.warn("Caught NoSuchElementException when attempting to classify objects in image");
                this.previousCapture = null;
            }
        }catch(Exception x){
            x.printStackTrace();
        }finally {
            if(predictor != null)
                predictor.close();
        }
        Duration timeElapsed = Duration.between(startCaptureTime, Instant.now());
        log.info("processCapturedEvent() "+captureCount + " : "+ timeElapsed); 
    }

    private boolean correctionCandidate(VideoCapturePayload latest){
        boolean isCorrectionCandidate = false;
        List<String> candidateReasons = new ArrayList<String>();
        if(!this.modelSL.modelClassesContains(latest.getDetectedObjectClassification())){
            candidateReasons.add(VideoCapturePayload.CORRECTION_REASONS.NOT_VALID_CLASS.name());
            isCorrectionCandidate=true;
        }
        if(latest.getDetected_object_probability() < this.correctionCandidateBestProbabilityThreshold) {
            candidateReasons.add(VideoCapturePayload.CORRECTION_REASONS.BEST_OBJECT_BELOW_PROBABILITY_THRESHOLD.name());
            isCorrectionCandidate=true;
        }
        for(Double probability: latest.getProbabilities()){
            if(probability < this.correctionCandidateMinimumProbabilityThreshold){
                candidateReasons.add(VideoCapturePayload.CORRECTION_REASONS.BELOW_MINIMAL_PROBABILITY_THRESHOLD.name());
                isCorrectionCandidate=true;
                break;
            }

        }
        if(latest.getDetectionCount() < this.correctionCandidateMinimumDetections){
            candidateReasons.add(VideoCapturePayload.CORRECTION_REASONS.TOO_LITTLE_OBJECTS_DETECTEDe.name());
            isCorrectionCandidate=true;
        }
        if(latest.getDetectionCount() > this.correctionCandidateMaximumDetections){
            candidateReasons.add(VideoCapturePayload.CORRECTION_REASONS.TOO_MANY_OBJECTS_DETECTED.name());
            isCorrectionCandidate=true;
        }

        latest.setCorrectionCandidateReasonList(candidateReasons);
        return isCorrectionCandidate;
    }

    private boolean isDifferent(VideoCapturePayload latest) {
        if(previousCapture == null){
            return true;
        }

        if(previousCapture.getDetectionCount() != latest.getDetectionCount()){
            log.debug("capture count different: "+previousCapture.getDetectionCount()+" : "+latest.getDetectionCount());
            return true;
        }
        if(!previousCapture.getDetectedObjectClassification().equals(latest.getDetectedObjectClassification()))
            return true;
        
        double pProb = previousCapture.getDetected_object_probability();
        double cProb = latest.getDetected_object_probability();
        double diff = cProb - pProb;
        double positiveDiff = Math.abs(diff);
        if(positiveDiff > this.predictionThreshold){
            log.warn("Just exceeded max probability threshold: "+this.predictionThreshold +" : "+positiveDiff);
            return true;
        }
        return false;
    }

    private static void drawBoundingBoxWithCustomizedDetections(Image img, DetectedObjects detections){
        List<BoundingBox> boxes = new ArrayList<>();
        List<String> names = new ArrayList<>();
        List<Double> prob = new ArrayList<>();
        for (Classifications.Classification obj : detections.items()) {
            DetectedObjects.DetectedObject objConvered = (DetectedObjects.DetectedObject) obj;
            BoundingBox box = objConvered.getBoundingBox();
            Rectangle rec = box.getBounds();
            Rectangle rec2 = new Rectangle(
                rec.getX() / 640,
                rec.getY() / 640,
                rec.getWidth() / 640,
                rec.getHeight() / 640
                );
            boxes.add(rec2);
            names.add(obj.getClassName());
            prob.add(obj.getProbability());
        }
        DetectedObjects converted = new DetectedObjects(names, prob, boxes);
        img.drawBoundingBoxes(converted);
    }

    private static BufferedImage toBufferedImage(Mat mat) {
        int width = mat.width();
        int height = mat.height();
        int type =
                mat.channels() != 1 ? BufferedImage.TYPE_3BYTE_BGR : BufferedImage.TYPE_BYTE_GRAY;
        
        if (type == BufferedImage.TYPE_3BYTE_BGR) {
            Imgproc.cvtColor(mat, mat, Imgproc.COLOR_BGR2RGB);
        }

        byte[] data = new byte[width * height * (int) mat.elemSize()];

        mat.get(0, 0, data);

        BufferedImage ret = new BufferedImage(width, height, type);
        ret.getRaster().setDataElements(0, 0, width, height, data);

        return ret;
    }
    
    private void refreshVideoCapture() {

        if(vCapture != null){
            vCapture.release();
            vCapture = null;
        }

        if(videoCaptureDevice > -1){

            OpenCV.loadShared();

            /* Determine groups
             *   troubleshoot:  podman run -it --rm  --group-add keep-groups quay.io/redhat_naps_da/djl-objectdetect-pytorch:0.0.3 id -a
             */
            UnixSystem uSystem = new UnixSystem();
            long[] groups = uSystem.getGroups();

            vCapture = new VideoCapture(videoCaptureDevice);
            if(!vCapture.isOpened())
                throw new RuntimeException("Unable to access video capture device w/ id = " + this.videoCaptureDevice+" and OS groups: "+Arrays.toString(groups));

            log.infov("refreshVideoCapture() video capture device = {0} is open =  {1}.", 
                this.videoCaptureDevice, 
                vCapture.isOpened());

        }else if(!StringUtils.isNullOrEmpty(this.testVideoFile)){

            log.info("Working Directory = " + System.getProperty("user.dir"));

            // Not actually needed
            // Just ensure opencv-java gstreamer1-plugin-libav packages are installed and "java.library.path" includes path to those installed C++ libraries
            //System.loadLibrary(Core.NATIVE_LIBRARY_NAME);

            OpenCV.loadShared();

            vCapture = new VideoCapture(this.testVideoFile, Videoio.CAP_ANY);
            log.infov("vCapture props: {0} {1} [2] [3]",
                vCapture.get(Videoio.CAP_PROP_FOURCC),
                vCapture.get(Videoio.CAP_PROP_FPS),
                vCapture.get(Videoio.CAP_PROP_FRAME_WIDTH),
                vCapture.get(Videoio.CAP_PROP_FRAME_HEIGHT) );
            if(!vCapture.isOpened()) {
                log.errorv("value of java.library.path = {0}", System.getProperty("java.library.path"));
                throw new RuntimeException("Unable to access test video = " + this.testVideoFile+" .  Do you have the following set correctly? :\n\t\t1) opencv-java & gstreamer packages installed (ie: dnf install opencv-java gstreamer1-plugin-libav)\n\t\t2) java.library.path includes path to shared libraries of opencv-java");
            }

            log.infov("start() video streaming on file = {0} is open =  {1}. Using NDManager {2}", 
                this.testVideoFile, 
                vCapture.isOpened());
        }else {
            throw new RuntimeException("need to specify either a video capture device or a video file");
        }
    }

     @Incoming(AppUtils.MODEL_NOTIFY)
     public void processModelStateChangeNotification(byte[] nMessageBytes) throws JsonMappingException, JsonProcessingException{
        String nMessage = new String(nMessageBytes);
        log.debugv("modelStateChangeNotification =  {0}", nMessage);

        ObjectMapper mapper = super.getObjectMapper();
        S3Notification modelN = mapper.readValue(nMessage, S3Notification.class);
        String key = modelN.key;

        if(AppUtils.S3_OBJECT_CREATED.equals(modelN.eventName)){

            this.stopPrediction();
            org.acme.apps.s3.Record record = modelN.records.get(0);
            String fileName = record.s3.object.key;
            String fileSize = record.s3.object.size;
            boolean success = s3ModelLifecycle.pullAndSaveModelZip(fileName);
            if(success){
                loadModel(this.modelZipPath, fileName);
                modelSL.unzipModelAndRefreshModelClassList();
                this.continueToPredict = true;
            }

        }else if(AppUtils.S3_OBJECT_DELETED.equals(modelN.eventName)) {
            log.warnv("WILL IGNORE model state change: type= {0} ; key= {1}", modelN.eventName, key);
        }else{
            log.errorv("WILL IGNORE model state change: type= {0} ; key= {1}", modelN.eventName, key);
        }
     }

    public ZooModel<?,?> getAppModel(){
        return model;
    }
    
    public Uni<Response> predict() {
        log.info("will now begin to predict on video capture stream");
        this.continueToPredict=true;
        Response eRes = Response.status(Response.Status.OK).entity(this.videoCaptureDevice).build();
        return Uni.createFrom().item(eRes);
    }


    public Uni<Response> stopPrediction() {

        log.info("stopPrediction");
        this.continueToPredict=false;
        this.previousCapture=null;
        Response eRes = Response.status(Response.Status.OK).entity(this.videoCaptureDevice).build();
        return Uni.createFrom().item(eRes);
    }

    public Uni<Response> refreshVideoAndPrediction() {
        this.refreshVideoCapture();
        this.refreshVideoCaptureStreamer();
        Response eRes = Response.status(Response.Status.OK).entity(this.videoCaptureDevice).build();
        return Uni.createFrom().item(eRes);
    }

    @PreDestroy
    public void shutdown() {
        multiCancellable.cancel();
        if(vCapture != null && vCapture.isOpened()){
            vCapture.release();
            log.infov("shutdown() video capture device = {0}", this.videoCaptureDevice );
        }
    }
}
