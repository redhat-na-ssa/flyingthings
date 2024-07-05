package org.acme.apps;

import io.smallrye.mutiny.Uni;
import jakarta.ws.rs.core.Response;

public interface ILiveObjectDetection extends IApp {

    public Uni<Response> refreshVideoAndPrediction();
    public boolean isCorrectionCandidate(VideoCapturePayload vcPayload);
    
}
