package org.acme.apps;

import java.time.Instant;

import org.opencv.core.Mat;

public class VideoCapturePayload {

    private Mat mat;
    private Instant startCaptureTime;
    private int captureCount;
    private int detectionCount;
    private String detectedObjectClassification;
    private double detected_object_probability;

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
