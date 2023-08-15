package org.acme.apps;

import java.io.IOException;
import java.time.Instant;
import java.util.List;

import org.opencv.core.Mat;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonPropertyOrder;
import com.fasterxml.jackson.annotation.JsonRawValue;
import com.fasterxml.jackson.annotation.JsonInclude.Include;
import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.DeserializationContext;
import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import com.fasterxml.jackson.databind.deser.std.StdDeserializer;
import com.fasterxml.jackson.databind.deser.std.StdKeyDeserializer;

import io.quarkus.runtime.util.StringUtil;

@JsonPropertyOrder({ "correctionReasons","payloadId","probabilitiesJSON","deviceId", "detectionCount","bestObjectClassification","bestObjectProbability","unadulteredImageFilePath", "base64EncodedImage" })
@JsonInclude(Include.NON_EMPTY)
public class VideoCapturePayload {

    public static final String CORRECTION_REASONS="correctionReasons";
    public static final String PAYLOAD_ID="payloadId";
    public static final String PROBABILITIES = "probabilities";
    public static final String PROBABILITIES_JSON="probabilitiesJSON";
    public static final String DEVICE_ID = "deviceId";
    public static final String DETECTION_COUNT = "detectionCount";
    public static final String BEST_OBJECT_CLASSIFICATION = "bestObjectClassification";
    public static final String BEST_OBJECT_PROBABILITY = "bestObjectProbability";
    public static final String UNADULTERED_IMAGE_FILE_PATH = "unadulteredImageFilePath";
    public static final String BASE64_ENCODED_IMAGE = "base64EncodedImage";
    public static final String DETECTED_IMAGE_FILE_PATH = "detectedImageFilePath";
    public static final String CAPTURE_TIMESTAMP = "captureTimestamp";
    public static final String CAPTURE_COUNT = "captureCount";
    public static final String NOT_STORED="not_stored";

    public enum CORRECTION_REASONS_ENUM {
        BEST_OBJECT_BELOW_PROBABILITY_THRESHOLD,
        ANY_OBJECT_BELOW_PROBABILITY_THRESHOLD,
        TOO_MANY_OBJECTS_DETECTED,
        TOO_LITTLE_OBJECTS_DETECTEDe,
        NOT_VALID_CLASS
    }

    private List<String> correctionReasons;
    private String payloadId;

    @JsonRawValue
    @JsonDeserialize(using = ProbabilitiesJSONDeserializer.class)
    private String probabilitiesJSON;

    private String deviceId;
    private int detectionCount;
    private String bestObjectClassification;
    private double bestObjectProbability;
    private String unadulteredImageFilePath=NOT_STORED;
    private String base64EncodedImage;

    @JsonIgnore
    private List<Double> probabilities;
    
    @JsonIgnore
    private int captureCount;

    @JsonIgnore
    private Instant startCaptureTime;

    @JsonIgnore
    private Mat mat;

    public String getProbabilitiesJSON() {
        return probabilitiesJSON;
    }
    public void setProbabilitiesJSON(String probabilitiesJSON) {
        this.probabilitiesJSON = probabilitiesJSON;
    }
    public String getUnadulteredImageFilePath() {
        return unadulteredImageFilePath;
    }
    public void setUnadulteredImageFilePath(String unadulteredImageFilePath) {
        this.unadulteredImageFilePath = unadulteredImageFilePath;
    }
    public String getPayloadId() {
        if(StringUtil.isNullOrEmpty(payloadId)){
            payloadId = deviceId+"-"+startCaptureTime.getEpochSecond();
        }
        return payloadId;
    }
    public void setPayloadId(String payloadId) {
        this.payloadId = payloadId;
    }

    public String getBase64EncodedImage() {
        return base64EncodedImage;
    }
    public void setBase64EncodedImage(String base64EncodedImage) {
        this.base64EncodedImage = base64EncodedImage;
    }
    public String getDeviceId() {
        return deviceId;
    }
    public void setDeviceId(String deviceId) {
        this.deviceId = deviceId;
    }
    public List<Double> getProbabilities() {
        return probabilities;
    }
    public void setProbabilities(List<Double> probabilities) {
        this.probabilities = probabilities;
    }
    public List<String> getCorrectionReasons() {
        return correctionReasons;
    }
    public void setCorrectionReasons(List<String> correctionCandidateStatement) {
        this.correctionReasons = correctionCandidateStatement;
    }
    public int getDetectionCount() {
        return detectionCount;
    }
    public void setDetectionCount(int detectionCount) {
        this.detectionCount = detectionCount;
    }
    public String getBestObjectClassification() {
        return bestObjectClassification;
    }
    public void setBestObjectClassification(String detectedObjectClassification) {
        this.bestObjectClassification = detectedObjectClassification;
    }
    public double getBestObjectProbability() {
        return bestObjectProbability;
    }
    public void setBestObjectProbability(double detected_object_probability) {
        this.bestObjectProbability = detected_object_probability;
    }
    public Mat getMat() {
        return mat;
    }
    public void setMat(Mat mat) {
        this.mat = mat;
    }
    public Instant getStartCaptureTime() {
        return startCaptureTime;
    }
    public void setStartCaptureTime(Instant startCaptureTime) {
        this.startCaptureTime = startCaptureTime;
    }
    public int getCaptureCount() {
        return captureCount;
    }
    public void setCaptureCount(int captureCount) {
        this.captureCount = captureCount;
    }
    
}


/* Avoids throwing the following exception:
        com.fasterxml.jackson.databind.exc.MismatchedInputException: Cannot deserialize value of type `java.lang.String` from Array value (token `JsonToken.START_ARRAY`)
 at [Source: (String)"{"correctionReasons":["BEST_OBJECT_BELOW_PROBABILITY_THRESHOLD","BELOW_MINIMAL_PROBABILITY_THRESHOLD"],"payloadId":"x1-1691857007","probabilitiesJSON":
        ...
        (through reference chain: org.acme.apps.VideoCapturePayload["probabilitiesJSON"])
 * 
 */
class ProbabilitiesJSONDeserializer extends StdDeserializer<String> {
    public ProbabilitiesJSONDeserializer() {
        this(null);
    }
    public ProbabilitiesJSONDeserializer(Class<?> c){
        super(c);
    }

    @Override
    public String deserialize(JsonParser jsonParser, DeserializationContext dContext) throws IOException, JsonProcessingException {
        return jsonParser.getText();
    }

}
