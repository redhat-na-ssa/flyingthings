package org.acme;

import java.util.Map;

import org.testcontainers.containers.FixedHostPortGenericContainer;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.utility.DockerImageName;

import io.quarkus.test.common.QuarkusTestResourceLifecycleManager;

public class CustomMQTTResource implements QuarkusTestResourceLifecycleManager{

    public static final String ARTEMIS_IMAGE="quay.io/artemiscloud/activemq-artemis-broker-init:artemis.2.28.0";
    public static final String MQTT_PORT="1883";

    DockerImageName IMAGE = DockerImageName.parse(ARTEMIS_IMAGE);
    
    final GenericContainer mqttServer = new FixedHostPortGenericContainer(ARTEMIS_IMAGE)
       .withFixedExposedPort(Integer.parseInt(MQTT_PORT), Integer.parseInt(MQTT_PORT))
       .withEnv("AMQ_USER", "djl")
       .withEnv("AMQ_PASSWORD", "djl");

    @Override
    public Map<String, String> start() {
        mqttServer.start();

        return Map.of("broker.internal.port", MQTT_PORT);
    }

    @Override
    public void stop() {
        mqttServer.stop();
    }
    
}
