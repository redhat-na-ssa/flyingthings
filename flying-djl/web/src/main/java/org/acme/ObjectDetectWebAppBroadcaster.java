package org.acme;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import io.smallrye.mutiny.Multi;

import org.eclipse.microprofile.reactive.messaging.Channel;
import org.jboss.logging.Logger;
import org.jboss.resteasy.reactive.RestStreamElementType;

@ApplicationScoped
@Path("djl-object-detect-web")
public class ObjectDetectWebAppBroadcaster {

    Logger log = Logger.getLogger("ObjectDetectWeAppBroadcaster");

    
    @Channel(AppUtils.LIVE_OBJECT_DETECTION)
    Multi<String> sseStream = null;


    // Test:   curl -N http://localhost:9080/djl-object-detect-web/event/objectDetectionStream
    @GET
    @Path("/event/objectDetectionStream")
    @Produces(MediaType.SERVER_SENT_EVENTS)
    @RestStreamElementType(MediaType.TEXT_PLAIN)
    public Multi<String> consumeSSE () {
        log.info("consumeSSE()");
        return this.sseStream;
    }

}
