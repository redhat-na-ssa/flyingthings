package org.acme;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.event.Observes;
import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import io.micrometer.core.instrument.MeterRegistry;
import io.quarkus.runtime.StartupEvent;
import io.quarkus.vertx.ConsumeEvent;
import io.smallrye.mutiny.Multi;
import io.vertx.mutiny.core.eventbus.EventBus;

import java.io.IOException;
import java.util.List;

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

    private static final String CORRECTION_REASON="correctionReason";
    private static final String TYPE="type";
    private static final String ALL="all";
    private static final String NO_CORRECTIVE_CANDIDATES = "noCorrectiveCandidates";
    Logger log = Logger.getLogger(ObjectDetectWebAppBroadcaster.class);

    @Inject
    S3CorrectionCandidateService s3CCService;

    
    @Channel(AppUtils.LIVE_OBJECT_DETECTION)
    Multi<String> sseStream = null;

    @Inject
    EventBus bus;

    JsonFactory jFactory;
    ObjectMapper oMapper;

    private final MeterRegistry mRegistry;

    ObjectDetectWebAppBroadcaster(MeterRegistry x) {
        this.mRegistry = x;
    }

    void start(@Observes StartupEvent event) {
        jFactory = new JsonFactory();
        s3CCService.doesBucketExist();

        oMapper = new ObjectMapper();

        this.sseStream
        .onSubscription().invoke(onItem -> {
            log.infov("Just subscribed to incoming stream at {0}", AppUtils.LIVE_OBJECT_DETECTION);
        })
        .subscribe()
            .with(onItem -> {
                if(isCorrectiveCandidate(onItem)){
                    bus.publish(AppUtils.MODEL_CORRECTIVE_CANDIDATES, onItem);
                }else{
                    mRegistry.counter(NO_CORRECTIVE_CANDIDATES, TYPE, ALL).increment();
                }
            });
    }


    // Test:   curl -N http://localhost:9080/djl-object-detect-web/event/objectDetectionStream
    @GET
    @Path("/event/objectDetectionStream")
    @Produces(MediaType.SERVER_SENT_EVENTS)
    @RestStreamElementType(MediaType.TEXT_PLAIN)
    public Multi<String> consumeSSE () {
        log.info("consumeSSE()");

        return this.sseStream;
    }
    
    // Consume raw video snapshots and apply prediction analysis
    @ConsumeEvent(AppUtils.MODEL_CORRECTIVE_CANDIDATES)
    public void processCapturedEvent(String sPayload){
        try {
            VideoCapturePayload vcPayload = oMapper.readValue(sPayload, VideoCapturePayload.class);
            s3CCService.postToBucket(sPayload, vcPayload.getPayloadId());

            // Create metrics based on corrective candidates
            // curl -X GET localhost:9080/q/metrics | grep modelCorrectiveCandidates_total
            mRegistry.counter(AppUtils.MODEL_CORRECTIVE_CANDIDATES, TYPE, ALL).increment();


            // curl -X GET localhost:9080/q/metrics | grep correctionReason_total
            List<String> cArray = vcPayload.getCorrectionReasons();
            for(String reason : cArray){
                mRegistry.counter(CORRECTION_REASON, TYPE, reason).increment();
            }
            
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
