package org.acme.apps;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.net.URLDecoder;
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
import com.fasterxml.jackson.databind.ObjectMapper;
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
import ai.djl.translate.TranslateException;

import java.awt.Graphics2D;
import java.awt.image.BufferedImage;

import com.sun.security.auth.module.UnixSystem;


@LookupIfProperty(name = "org.acme.djl.resource", stringValue = "LiveObjectDetectionResource")
@ApplicationScoped
public class LiveObjectDetectionResource extends BaseResource implements ILiveObjectDetection {

    private static final String PATTERN_FORMAT = "yyyy.MM.dd HH:mm:ss";
    private static final String NO_VIDEO_FILE="NO_VIDEO_FILE";

    private static Logger log = Logger.getLogger("LiveObjectDetectionResource");

    AtomicInteger schedulerCount = new AtomicInteger();

    @ConfigProperty(name = "org.acme.objecdetection.image.directory", defaultValue="/tmp/org.acme.objectdetection")
    String oDetectionDirString;

    @ConfigProperty(name = "org.acme.objectdetection.video.capture.device.id", defaultValue = "-1")
    int videoCaptureDevice;

    @ConfigProperty(name = "org.acme.objectdetection.video.file", defaultValue = NO_VIDEO_FILE)
    String videoFile;

    @ConfigProperty(name = "org.acme.objectdetection.test.video.frame.path", defaultValue = AppUtils.NA)
    String testVideoFramePath;

    @ConfigProperty(name = "org.acme.objectdetection.write.unadultered.image.to.disk", defaultValue = "True")
    boolean writeUnAdulateredImageToDisk;

    @ConfigProperty(name = "org.acme.objectdetection.write.modified.image.to.disk", defaultValue = "False")
    boolean writeModifiedImageToDisk;

    @ConfigProperty(name = "org.acme.objectdetection.prediction.change.threshold", defaultValue = "0.1")
    double predictionThreshold;

    @ConfigProperty(name = "org.acme.objectdetection.video.capture.interval.millis", defaultValue = "50")
    int videoCaptureIntevalMillis;

    @ConfigProperty(name = "org.acme.objectdetection.video.capture.delay.millis", defaultValue = "5000")
    int vCaptureDelayMillis=5000;

    @ConfigProperty(name = "org.acme.objectdetection.healthcheck.delay.millis", defaultValue = "2000")
    int healthCheckStartDelayMillis = 2000;

    @ConfigProperty(name = "org.acme.objectdetection.healthcheck.interval.millis", defaultValue = "10000")
    int healthCheckIntervalMillis = 10000;

    @ConfigProperty(name = "org.acme.djl.model.zip.path", defaultValue = AppUtils.NA)
    String modelZipPath;

    @ConfigProperty(name = "org.acme.djl.model.zip.name", defaultValue = AppUtils.NA)
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

    @ConfigProperty(name = "mp.messaging.outgoing.liveObjectDetection.max-message-size")
    int payloadImageMaxSizeBytes;

    @ConfigProperty(name = "org.acme.objectdetection.resize.image.width", defaultValue = "640")
    int resizedWidth;

    @ConfigProperty(name = "org.acme.objectdetection.resize.image.height", defaultValue = "480")
    int resizedHeight;

    @Inject
    CriteriaFilter cFilters;

    @Inject
    EventBus bus;

    @Inject
    S3ModelLifecycle s3ModelLifecycle;

    @Inject
    ModelStorageLifecycle modelSL;

    @Inject
    HealthCheckMonitor hMonitor;

    ZooModel<Image, DetectedObjects> model;
    AppStatus aStatus = new AppStatus();
    File rawAndBoxedImageFileDir;
    VideoCapture vCapture = null;
    VideoCapturePayload previousCapture;
    DateTimeFormatter formatter = DateTimeFormatter.ofPattern(PATTERN_FORMAT).withZone(ZoneId.systemDefault());
    Cancellable multiVCaptureCancellable = null;
    Cancellable multiHealthCancellable = null;
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

            // 4)  Populate List of classes so as to assist with identifying models that need correction
            modelSL.unzipModelAndRefreshModelClassList();

            // 5)  Load model and unzip
            loadModel(this.modelZipPath, this.modelZipName);

            // 6)  Keep pace with video buffer by reading frames from it at a configurable number of millis
            //     On a different thread, this app will periodically evaluate the latest captured frame at that instant in time
            refreshVideoCaptureStreamer();

            // 7) Begin to monitor health of various components such as MQTT connection
            monitorHealth();

        }catch(RuntimeException x) {
            throw x;
        }catch(Throwable x){
            throw new RuntimeException(x);
        }finally {
            
        }
    }

    private void refreshVideoCaptureStreamer() {
        if(multiVCaptureCancellable != null){
            multiVCaptureCancellable.cancel();
            multiVCaptureCancellable = null;
            vCaptureStreamer = null;
            aStatus.setVideoStatus(false);
        }

        vCaptureStreamer = Multi.createFrom()
            .ticks().startingAfter(Duration.ofMillis(vCaptureDelayMillis)).every((Duration.ofMillis(videoCaptureIntevalMillis))).onCancellation().invoke( () -> {
                log.info("just cancelled video capture streamer");
        });
        multiVCaptureCancellable = vCaptureStreamer.subscribe().with( (i) -> {
            if(vCapture != null)
            vCapture.read(unboxedMat);
        });
        aStatus.setVideoStatus(true);
    }

    private void loadModel(String newModelZipPath, String newModelZipName) {

        String existingModelFilePath = this.modelZipPath+"/"+this.modelZipName;
        String newModelFilePath = newModelZipPath+"/"+newModelZipName;
        try { 
            Criteria.Builder<Image, DetectedObjects> cBuilder = Criteria.builder()
            .setTypes(Image.class, DetectedObjects.class) // defines input and output data type
            .optEngine("OnnxRuntime")  // Specify OnnX explicitly because classpath also includes pytorch
            .optTranslatorFactory(new YoloV5TranslatorFactory())
            .optProgress(new ProgressBar())
            .optArgument("optApplyRatio", true)  // post process
            .optArgument("rescale", true); // post process
            
            // If a custom model is not specified, then have DJL pull its default model for ONNX engine
            if(!AppUtils.NA.equals(newModelZipPath)){
                log.infov("loadModel() {0}", newModelFilePath);
                cBuilder
                    .optModelUrls(newModelFilePath)
                    .optModelName(this.modelName)
                    .optArgument("synsetFileName", this.synsetFileName);
            }

            Criteria<Image, DetectedObjects> criteria = cBuilder.build();

            ZooModel<Image, DetectedObjects> newModel = criteria.loadModel();

            // Don't even bother testing model if its just the default model provided by DJL
            if(!AppUtils.NA.equals(newModelZipPath)){
                testModel(newModel);
            }

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
        
        if (aStatus.continueToPredict() && !unboxedMat.empty()) {
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

    private void testModel(ZooModel<Image, DetectedObjects> newModel) throws TranslateException, IOException, ValidationException{

        File testVideoFrameFile = new File(this.testVideoFramePath);
        if(!testVideoFrameFile.exists()){
            log.warnv("Unable to locate test video from at {0}.  Will not test model", this.testVideoFramePath);
            return;
        }
        InputStream fis = null;
        Predictor<Image, DetectedObjects> predictor = null;
        try{
            fis = new FileInputStream(testVideoFrameFile);
            predictor = newModel.newPredictor();
            ImageFactory factory = ImageFactory.getInstance();
            DetectedObjects detections = predictor.predict(factory.fromInputStream(fis));

            // Create VideoCapturePayload object and populate with detections
            VideoCapturePayload cPayload = new VideoCapturePayload();
            cPayload.setCaptureCount(1);
            Instant startCaptureTime = Instant.now();
            cPayload.setStartCaptureTime(startCaptureTime);
            this.populateVideoCaptureWithDetections(cPayload, detections);

            boolean isCorrectionCandidate = isCorrectionCandidate(cPayload);
            if(!isCorrectionCandidate)
                log.infov("testModel() model {0} is good to go!", newModel.getName());
            else{
                log.errorv("testModel() model failed due to: {0}", cPayload.getCorrectionReasons().toString());
                log.errorv("{0}", detections);
                throw new ValidationException(newModel.getName()+" did not pass tests");
            }
        }finally{
            if(predictor!=null)predictor.close();
            if(fis!=null){try{fis.close();}catch(Exception x){x.printStackTrace();}}
        }
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
            log.debugv("{0}", detections);
            
            this.populateVideoCaptureWithDetections(capturePayload, detections);
            
            // Determine whether this VideoCapture is a candidate to correct the model and/or there is a state change
            boolean isCorrectionCandidate = isCorrectionCandidate(capturePayload);
            boolean isDifferent = isDifferent(capturePayload);
            
            // generate an event if either correctionCandidate or if there is a state change
            if(isCorrectionCandidate || isDifferent){
                
                if(isCorrectionCandidate){
                    String correctionReasons = capturePayload.getCorrectionReasons().toString();
                    if(includePredictionDumpInCorrectionsMessage){
                        capturePayload.setProbabilitiesJSON(detections.toJson());
                    }
                    log.warnv("correction candidate! reasons = {0}", correctionReasons);
                }
                
                capturePayload.setDeviceId(System.getenv(AppUtils.HOSTNAME));
                
                if(writeUnAdulateredImageToDisk){
                    // Write un-boxed image to local file system
                    File uBoxedImageFile = new File(rawAndBoxedImageFileDir,  "unAdulteredImage-"+startCaptureTime.getEpochSecond() +".png");
                    BufferedImage uBoxedImage = toBufferedImage(unboxedMat);
                    ImageIO.write(uBoxedImage, "png", uBoxedImageFile);
                    capturePayload.setUnadulteredImageFilePath(uBoxedImageFile.getAbsolutePath());
                }
                
                try {
                    // Annotate video capture image w/ any detected objects
                    // Consider over-riding the following function so as to include the predictions for each detected object:
                    //   https://github.com/deepjavalibrary/djl/blob/master/extensions/opencv/src/main/java/ai/djl/opencv/OpenCVImage.java#L158-L200
                    img.drawBoundingBoxes(detections);

                    // Encode binary image to Base64 string and add to payload
                    Mat boxedImage = (Mat)img.getWrappedImage();
                    BufferedImage bBoxedImage = toBufferedImage(boxedImage);
                    byte[] bytes = toPngByteArray(bBoxedImage);
                    if(this.payloadImageMaxSizeBytes < bytes.length) {
                        int originalBytesLength = bytes.length;
                        bytes = resizeImage(bBoxedImage);
                        log.warnv("Resized image due to exceeding max bytes: {0} : {1} : {2}", this.payloadImageMaxSizeBytes, originalBytesLength, bytes.length);
                    }
                    String stringEncodedImage = Base64.getEncoder().encodeToString(bytes);
                    capturePayload.setBase64EncodedImage(stringEncodedImage);

                    if(writeModifiedImageToDisk) {
                        File boxedImageFile = new File(rawAndBoxedImageFileDir,  "boxedImage-"+ startCaptureTime.getEpochSecond()+".png");
                        ImageIO.write(bBoxedImage, "png", boxedImageFile);
                        log.infov("Path to boxedImageFile = {0}", boxedImageFile.getAbsolutePath());
                    }
                }catch(NoSuchElementException x) {
                    log.warn("Caught NoSuchElementException when attempting to classify objects in image");
                    this.previousCapture = null;
                }
    
                ObjectMapper oMapper = super.getObjectMapper();
                String payloadString = oMapper.writeValueAsString(capturePayload);
    
                bus.publish(AppUtils.LIVE_OBJECT_DETECTION, payloadString);
    
                this.previousCapture = capturePayload;
            }else {
                log.debug("not a correction candidate nor is there a state change");
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

    private void populateVideoCaptureWithDetections(VideoCapturePayload cPayload, DetectedObjects detections){
        cPayload.setDetectionCount(detections.getNumberOfObjects());
        if(cPayload.getDetectionCount() > 0){
            Classifications.Classification dClass = detections.best();
            List<Double> probabilities = detections.getProbabilities();
            cPayload.setProbabilities(probabilities);
            cPayload.setBestObjectClassification(dClass.getClassName());
            cPayload.setBestObjectProbability(dClass.getProbability());
        }
    }

    /*
     * Business rules to determine if predictive inference results on a specific video frame could be used as a candidate to improve the model.
     * NOTE:  more than 1 business rule can be triggered
     * 
     * Potential improvements:
     *   1)  Don't hard-code these business rules here in Java.
     *         Instead, make use of a business rules engine (ie:  drools) and implement these business rules in the DSL (ie: Drools Rules Language (DRL)) of that rule engine
     */
    public boolean isCorrectionCandidate(VideoCapturePayload vcPayload){
        boolean isCorrectionCandidate = false;
        List<String> candidateReasons = new ArrayList<String>();

        // Rule #1:  Is class of best detected object included in list of classes for model (typically listed in classes.txt or synset.txt) ?
        if(!this.modelSL.modelClassesContains(vcPayload.getBestObjectClassification())){
            candidateReasons.add(VideoCapturePayload.CORRECTION_REASONS_ENUM.NOT_VALID_CLASS.name());
            isCorrectionCandidate=true;
        }

        // Rule #2:  Does best detected object have a probability of less than a configurable probability threshold (default 80%) ?
        if(vcPayload.getBestObjectProbability() < this.correctionCandidateBestProbabilityThreshold) {
            candidateReasons.add(VideoCapturePayload.CORRECTION_REASONS_ENUM.BEST_OBJECT_BELOW_PROBABILITY_THRESHOLD.name());
            isCorrectionCandidate=true;
        }

        // Rule #3:  Is the probability of any detected object less than a configurable probability threshold (default 90%) ?
        if(vcPayload.getProbabilities() != null) {
            for(Double probability: vcPayload.getProbabilities()){
                if(probability < this.correctionCandidateMinimumProbabilityThreshold){
                    candidateReasons.add(VideoCapturePayload.CORRECTION_REASONS_ENUM.ANY_OBJECT_BELOW_PROBABILITY_THRESHOLD.name());
                    isCorrectionCandidate=true;
                    break;
                }
    
            }
        }

        // Rule #4:  Are the # of detected objects less than a configurable threshold (default 1) ?
        if(vcPayload.getDetectionCount() < this.correctionCandidateMinimumDetections){
            candidateReasons.add(VideoCapturePayload.CORRECTION_REASONS_ENUM.TOO_FEW_OBJECTS_DETECTED.name());
            isCorrectionCandidate=true;
        }

        // Rule #5:  Are the # of detected objects more than a configurable threshold (default 5) ?
        if(vcPayload.getDetectionCount() > this.correctionCandidateMaximumDetections){
            candidateReasons.add(VideoCapturePayload.CORRECTION_REASONS_ENUM.TOO_MANY_OBJECTS_DETECTED.name());
            isCorrectionCandidate=true;
        }


        vcPayload.setCorrectionReasons(candidateReasons);
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
        if(!previousCapture.getBestObjectClassification().equals(latest.getBestObjectClassification()))
            return true;
        
        double pProb = previousCapture.getBestObjectProbability();
        double cProb = latest.getBestObjectProbability();
        double diff = cProb - pProb;
        double positiveDiff = Math.abs(diff);
        if(positiveDiff > this.predictionThreshold){
            log.warn("Just exceeded max probability threshold: "+this.predictionThreshold +" : "+positiveDiff);
            return true;
        }
        return false;
    }


    private byte[] resizeImage(BufferedImage bBoxedImage) throws IOException {
        java.awt.Image resizedImage = bBoxedImage.getScaledInstance(this.resizedWidth, this.resizedHeight, java.awt.Image.SCALE_SMOOTH);
        BufferedImage resizedBImage = toBufferedImage(resizedImage);
        return toPngByteArray(resizedBImage);
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

    private static BufferedImage toBufferedImage(java.awt.Image img) {

        if (img instanceof BufferedImage) {
            return (BufferedImage) img;
        }

        // Create a buffered image with transparency
        BufferedImage bi = new BufferedImage(
                img.getWidth(null), img.getHeight(null),
                BufferedImage.TYPE_INT_ARGB);

        Graphics2D graphics2D = bi.createGraphics();
        graphics2D.drawImage(img, 0, 0, null);
        graphics2D.dispose();

        return bi;
    }

    
    private static byte[] toPngByteArray(BufferedImage bImage) throws IOException {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        ImageIO.write(bImage, "png", baos);
        byte[] pngBytes = baos.toByteArray();
        baos.close();
        return pngBytes;
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

        }else if(!StringUtils.isNullOrEmpty(this.videoFile)){

            log.info("Working Directory = " + System.getProperty("user.dir"));

            // Not actually needed
            // Just ensure opencv-java gstreamer1-plugin-libav packages are installed and "java.library.path" includes path to those installed C++ libraries
            //System.loadLibrary(Core.NATIVE_LIBRARY_NAME);

            OpenCV.loadShared();

            vCapture = new VideoCapture(this.videoFile, Videoio.CAP_ANY);
            log.infov("vCapture props: {0} {1} [2] [3]",
                vCapture.get(Videoio.CAP_PROP_FOURCC),
                vCapture.get(Videoio.CAP_PROP_FPS),
                vCapture.get(Videoio.CAP_PROP_FRAME_WIDTH),
                vCapture.get(Videoio.CAP_PROP_FRAME_HEIGHT) );
            if(!vCapture.isOpened()) {
                log.errorv("value of java.library.path = {0}", System.getProperty("java.library.path"));
                throw new RuntimeException("Unable to access test video = " + this.videoFile+" .  Do you have the following set correctly? :\n\t\t1) opencv-java & gstreamer packages installed (ie: dnf install opencv-java gstreamer1-plugin-libav)\n\t\t2) java.library.path includes path to shared libraries of opencv-java");
            }

            log.infov("start() video streaming on file = {0} is open =  {1}. Using NDManager {2}", 
                this.videoFile, 
                vCapture.isOpened());
        }else {
            throw new RuntimeException("need to specify either a video capture device or a video file");
        }
    }

    private void monitorHealth() {

        log.info("monitorHealth() starting .....");
        Multi<Long> healthStreamer = Multi.createFrom()
            .ticks().startingAfter(Duration.ofMillis(healthCheckStartDelayMillis)).every((Duration.ofMillis(healthCheckIntervalMillis)))
            .onFailure().invoke(e -> {
                log.error("error with health check: "+e.getMessage());
            })
            .onCancellation().invoke( () -> {
                log.info("just cancelled health check streamer");
            });

        multiHealthCancellable = healthStreamer.subscribe().with( (i) -> {

            try {
                aStatus.setSmallryeStatus(hMonitor.sitRep());
            } catch (Throwable e) {
                aStatus.setSmallryeStatus(false);
                e.printStackTrace();
            }
        });
    }

     @Incoming(AppUtils.MODEL_NOTIFY)
     public void processModelStateChangeNotification(byte[] nMessageBytes) throws JsonMappingException, JsonProcessingException, UnsupportedEncodingException{
        String nMessage = new String(nMessageBytes);
        log.debugv("modelStateChangeNotification =  {0}", nMessage);

        ObjectMapper mapper = super.getObjectMapper();
        S3Notification modelN = mapper.readValue(nMessage, S3Notification.class);
        String key = modelN.key;

        if(AppUtils.S3_OBJECT_CREATED.equals(modelN.eventName)){

            this.stopPrediction();
            this.aStatus.setModelStatus(false);
            org.acme.apps.s3.Record record = modelN.records.get(0);
            String fileName = URLDecoder.decode(record.s3.object.key, "UTF-8");
            String fileSize = record.s3.object.size;
            boolean success = s3ModelLifecycle.pullAndSaveModelZip(fileName);
            if(success){
                loadModel(this.modelZipPath, fileName);
                modelSL.unzipModelAndRefreshModelClassList();
                this.aStatus.setModelStatus(success);
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
        this.aStatus.setApiStatus(true);
        Response eRes = Response.status(Response.Status.OK).entity(this.videoCaptureDevice).build();
        return Uni.createFrom().item(eRes);
    }


    public Uni<Response> stopPrediction() {

        log.info("stopPrediction");
        this.aStatus.setApiStatus(false);
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
        multiVCaptureCancellable.cancel();
        if(vCapture != null && vCapture.isOpened()){
            vCapture.release();
            log.infov("shutdown() video capture device = {0}", this.videoCaptureDevice );
        }

        multiHealthCancellable.cancel();
    }

    class AppStatus {
    
        boolean smallryeStatus = false;
        boolean videoStatus = false;
        boolean modelStatus = true;
        boolean apiStatus = true;
    
        public void setSmallryeStatus(boolean smallryeStatus) {
            this.smallryeStatus = smallryeStatus;
        }
    
        public void setVideoStatus(boolean videoStatus) {
            this.videoStatus = videoStatus;
        }
    
        public void setModelStatus(boolean x){
            modelStatus = x;
        }
    
        public void setApiStatus(boolean x){
            apiStatus = x;
        }
    
        public boolean continueToPredict(){
            if(!smallryeStatus || !videoStatus || !modelStatus || !apiStatus){
                log.warnv("continueToPredict() [smallryeStatus,videoStatus,modelStatus,apiStatus] {0}, {1}, {2}, {3}", smallryeStatus, videoStatus, modelStatus, apiStatus);
                return false;
            }
    
            return true;
        }
    
    
    }
}

