///usr/bin/env jbang "$0" "$@" ; exit $?
//JAVA 11+
// Update the Quarkus version to what you want here or run jbang with
// `-Dquarkus.version=<version>` to override it.
//DEPS io.quarkus:quarkus-bom:${quarkus.version:2.16.3.Final}@pom
//DEPS io.quarkus:quarkus-picocli
//DEPS io.quarkus:quarkus-smallrye-reactive-messaging-mqtt
//FILES application.properties

import picocli.CommandLine;

import java.util.concurrent.CompletionStage;

import javax.enterprise.context.Dependent;
import javax.inject.Inject;

import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.eclipse.microprofile.reactive.messaging.Message;
import org.jboss.logging.Logger;

@CommandLine.Command
public class mqtt_consumer implements Runnable {

    public static final String LIVE_OBJECT_DETECTION = "liveObjectDetection";

    @Inject
    CommandLine.IFactory factory;

    private final MQTTService mqttService;

    public mqtt_consumer(MQTTService mqttService) {
        this.mqttService = mqttService;
    }

    @Override
    public void run() {
        while(true) {
            try {
                Thread.sleep(5000);
            } catch (InterruptedException e) {
            }
        }
    }

}

@Dependent
class  MQTTService {
    public static final Logger log = Logger.getLogger("MQTTService");

    @Incoming(value = mqtt_consumer.LIVE_OBJECT_DETECTION)
    CompletionStage<Void> consumeMQTT(Message<byte[]> msg) {
        String payload = new String(msg.getPayload());
        log.info(payload);
        return msg.ack();
    }
}
