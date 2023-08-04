package org.acme.apps;

import java.time.Instant;
import java.util.List;

import org.opencv.core.Mat;

public class VideoCapturePayload {

    public enum CORRECTION_REASONS {
        BEST_OBJECT_BELOW_PROBABILITY_THRESHOLD,
        BELOW_MINIMAL_PROBABILITY_THRESHOLD,
        TOO_MANY_OBJECTS_DETECTED,
        TOO_LITTLE_OBJECTS_DETECTEDe,
        NOT_VALID_CLASS
    }

    private Mat mat;
    private Instant startCaptureTime;
    private int captureCount;
    private int detectionCount;
    private String detectedObjectClassification;
    private double detected_object_probability;
    private List<String> correctionCandidateReasonList;
    private List<Double> probabilities;

    public List<Double> getProbabilities() {
        return probabilities;
    }
    public void setProbabilities(List<Double> probabilities) {
        this.probabilities = probabilities;
    }
    public List<String> getCorrectionCandidateReasonList() {
        return correctionCandidateReasonList;
    }
    public void setCorrectionCandidateReasonList(List<String> correctionCandidateStatement) {
        this.correctionCandidateReasonList = correctionCandidateStatement;
    }
    public int getDetectionCount() {
        return detectionCount;
    }
    public void setDetectionCount(int detectionCount) {
        this.detectionCount = detectionCount;
    }
    public String getDetectedObjectClassification() {
        return detectedObjectClassification;
    }
    public void setDetectedObjectClassification(String detectedObjectClassification) {
        this.detectedObjectClassification = detectedObjectClassification;
    }
    public double getDetected_object_probability() {
        return detected_object_probability;
    }
    public void setDetected_object_probability(double detected_object_probability) {
        this.detected_object_probability = detected_object_probability;
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
