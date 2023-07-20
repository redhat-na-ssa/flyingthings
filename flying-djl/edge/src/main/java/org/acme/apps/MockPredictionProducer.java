package org.acme.apps;

import jakarta.enterprise.context.ApplicationScoped;

import org.jboss.logging.Logger;

import io.quarkus.arc.lookup.LookupIfProperty;
import io.quarkus.vertx.ConsumeEvent;

import org.acme.AppUtils;

/* 
 * TO-DO: This class continues to get instantiated regarding of value of the lookup property
 */
@LookupIfProperty(name = "org.acme.djl.prediction.producer", stringValue = "MockPredictionProducer")
@ApplicationScoped
public class MockPredictionProducer implements PredictionProducer {

    private static final Logger log = Logger.getLogger("MockPredictionProducer");

    @ConsumeEvent(AppUtils.LIVE_OBJECT_DETECTION)
    public boolean send(String message) {
        log.infov("send() message of length in bytes = {0}", message.length());
        return true;
    }
    
}
