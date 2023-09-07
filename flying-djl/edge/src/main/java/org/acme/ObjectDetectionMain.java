package org.acme;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.event.Observes;
import jakarta.enterprise.inject.Instance;
import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.sse.OutboundSseEvent;
import jakarta.ws.rs.sse.Sse;
import jakarta.ws.rs.sse.SseEventSink;

import org.acme.apps.ILiveObjectDetection;
import io.quarkus.runtime.StartupEvent;
import io.quarkus.vertx.ConsumeEvent;
import io.smallrye.mutiny.Uni;

import org.jboss.logging.Logger;

//https://github.com/limadelrey/quarkus-sse/blob/master/src/main/java/org/limadelrey/quarkus/sse/SimpleSSE.java

@ApplicationScoped
@Path("djl")
public class ObjectDetectionMain extends DJLMain {

    Logger log = Logger.getLogger("ObjectDetectionMain");

    private OutboundSseEvent.Builder eventBuilder;

    @Context
    protected Sse sse;

    private SseEventSink sseEventSink = null;

    @Inject
    Instance<ILiveObjectDetection> lidInstance;

    @POST
    @Path("/refreshVideoAndPrediction")
    @Produces(MediaType.APPLICATION_JSON)
    public Uni<Response> refreshVideoAndPrediction() {
        return lidInstance.get().refreshVideoAndPrediction();
    }

    void startup(@Observes StartupEvent event)  {

        super.setDjlApp( lidInstance.get() );

        log.info("startup() djlApp = "+lidInstance.get());

        this.eventBuilder = sse.newEventBuilder();

    }

    @ConsumeEvent(AppUtils.LIVE_OBJECT_DETECTION)
    public void consumeLiveObjectDetect(String event){
        if(sseEventSink != null && !sseEventSink.isClosed()){

            final OutboundSseEvent sseEvent = this.eventBuilder
              .mediaType(MediaType.APPLICATION_JSON_TYPE)
              .data(event)
              .reconnectDelay(3000)
              .build();
          sseEventSink.send(sseEvent);
        }

    }

    // Test:   curl -N http://localhost:8080/djl/event/objectDetectionStream
    @GET
    @Path("/event/objectDetectionStream")
    @Produces(MediaType.SERVER_SENT_EVENTS)
    public void consumeSSE (@Context SseEventSink sseEventSink) {
        this.sseEventSink = sseEventSink;
    }

}
