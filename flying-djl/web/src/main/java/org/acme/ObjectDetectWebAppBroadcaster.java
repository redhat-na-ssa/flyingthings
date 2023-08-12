package org.acme;

import jakarta.annotation.PostConstruct;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import io.quarkus.vertx.ConsumeEvent;
import io.smallrye.mutiny.Multi;
import io.vertx.mutiny.core.eventbus.EventBus;

import java.io.IOException;

import org.acme.apps.VideoCapturePayload;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.jboss.logging.Logger;
import org.jboss.resteasy.reactive.RestStreamElementType;

import com.fasterxml.jackson.core.JsonFactory;
import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

@ApplicationScoped
@Path("djl-object-detect-web")
public class ObjectDetectWebAppBroadcaster {

    Logger log = Logger.getLogger("ObjectDetectWeAppBroadcaster");

    @Inject
    S3CorrectionCandidateService s3CCService;

    
    @Channel(AppUtils.LIVE_OBJECT_DETECTION)
    Multi<String> sseStream = null;

    @Inject
    EventBus bus;

    JsonFactory jFactory;
    ObjectMapper oMapper;

    @PostConstruct
    public void start() {
        jFactory = new JsonFactory();
        s3CCService.doesBucketExist();

        oMapper = new ObjectMapper();
    }


    // Test:   curl -N http://localhost:9080/djl-object-detect-web/event/objectDetectionStream
    @GET
    @Path("/event/objectDetectionStream")
    @Produces(MediaType.SERVER_SENT_EVENTS)
    @RestStreamElementType(MediaType.TEXT_PLAIN)
    public Multi<String> consumeSSE () {
        log.info("consumeSSE()");
        this.sseStream.subscribe().with(onItem -> {
            if(isCorrectiveCandidate(onItem)){
                bus.publish(AppUtils.MODEL_CORRECTIVE_CANDIDATES, onItem);
            }
        });
        return this.sseStream;
    }
    
    // Consume raw video snapshots and apply prediction analysis
    @ConsumeEvent(AppUtils.MODEL_CORRECTIVE_CANDIDATES)
    public void processCapturedEvent(String sPayload){
        try {
            VideoCapturePayload vcPayload = oMapper.readValue(sPayload, VideoCapturePayload.class);
            s3CCService.postToBucket(sPayload, vcPayload.getPayloadId());
            
        } catch (JsonProcessingException e) {
            e.printStackTrace();
        }

    }

    private boolean isCorrectiveCandidate(String message){
        boolean response = false;
        JsonParser jParser = null;
        try {
            jParser = jFactory.createParser(message);

            // Assumes that if VideoCapturePayload.CORRECTION_REASONS is included in payload, then it will be the first element
            jParser.nextToken(); // "{"
            jParser.nextToken();
            String firstFieldName = jParser.getCurrentName();
            
            if(VideoCapturePayload.CORRECTION_REASONS.equals(firstFieldName)){
                response=true;
            }
        } catch (IOException e) {
            e.printStackTrace();
        }finally {
            if(jParser != null){
                try {
                    jParser.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
        return response;
    }

}
