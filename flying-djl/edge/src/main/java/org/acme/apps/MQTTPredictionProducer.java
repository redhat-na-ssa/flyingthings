package org.acme.apps;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

import org.jboss.logging.Logger;

import io.quarkus.arc.lookup.LookupIfProperty;
import io.quarkus.vertx.ConsumeEvent;

import org.acme.AppUtils;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;

@LookupIfProperty(name = "org.acme.djl.prediction.producer", stringValue = "MQTTPredictionProducer")
@ApplicationScoped
public class MQTTPredictionProducer implements PredictionProducer {

    private static final Logger log = Logger.getLogger("MQTTPredictionProducer");

    @Inject
    @Channel(AppUtils.LIVE_OBJECT_DETECTION)
    Emitter<String> eventChannel;


    @ConsumeEvent(AppUtils.LIVE_OBJECT_DETECTION)
    public boolean send(String message) {
        //log.infov("send() message = {0}", message);
        eventChannel.send(message);
        return true;
    }
    
}
