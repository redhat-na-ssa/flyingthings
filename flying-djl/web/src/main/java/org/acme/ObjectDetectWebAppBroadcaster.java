package org.acme;

import jakarta.annotation.PostConstruct;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import io.opentelemetry.api.internal.StringUtils;
import io.smallrye.mutiny.Multi;

import java.io.IOException;

import org.eclipse.microprofile.reactive.messaging.Channel;
import org.jboss.logging.Logger;
import org.jboss.resteasy.reactive.RestStreamElementType;

import com.fasterxml.jackson.core.JsonFactory;
import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.core.JsonToken;

@ApplicationScoped
@Path("djl-object-detect-web")
public class ObjectDetectWebAppBroadcaster {

    Logger log = Logger.getLogger("ObjectDetectWeAppBroadcaster");

    @Inject
    S3CorrectionCandidateService s3CCService;

    
    @Channel(AppUtils.LIVE_OBJECT_DETECTION)
    Multi<String> sseStream = null;

    JsonFactory jFactory;

    @PostConstruct
    public void start() {
        jFactory = new JsonFactory();
        s3CCService.doesBucketExist();
    }


    // Test:   curl -N http://localhost:9080/djl-object-detect-web/event/objectDetectionStream
    @GET
    @Path("/event/objectDetectionStream")
    @Produces(MediaType.SERVER_SENT_EVENTS)
    @RestStreamElementType(MediaType.TEXT_PLAIN)
    public Multi<String> consumeSSE () {
        log.info("consumeSSE()");
        this.sseStream.subscribe().with(onItem -> {
            String fileName = this.identifyCorrectiveCandidate(onItem);
            if(!StringUtils.isNullOrEmpty(fileName)){
                s3CCService.postToBucket(onItem, fileName);
            }
        });
        return this.sseStream;
    }

    private String identifyCorrectiveCandidate(String message){
        String response = null;
        JsonParser jParser = null;
        try {
            jParser = jFactory.createParser(message);

            // Assumes that if AppUtils.CORRECTION_REASONS is included in payload, then it will be the first element
            jParser.nextToken(); // "{"
            jParser.nextToken();
            String firstFieldName = jParser.getCurrentName();
            jParser.nextToken();
            String firstFielValue = jParser.getText();
            
            if(AppUtils.CORRECTION_REASONS.equals(firstFieldName)){
                log.infov("identifyCorrectiveCandidate() message size = {0}; fieldname = {1} {2}", message.length(), firstFieldName, firstFielValue);
                while(jParser.nextToken() != JsonToken.END_OBJECT){
                    if(AppUtils.ID.equals(jParser.currentName())){
                        jParser.nextToken();
                        return jParser.getText();
                    }
                }
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
