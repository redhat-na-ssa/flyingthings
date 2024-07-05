package org.acme.apps;

import org.eclipse.microprofile.rest.client.inject.RestClient;
import org.jboss.logging.Logger;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonMappingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

@ApplicationScoped
public class HealthCheckMonitor {

    private static final String STATUS = "status";
    private static final String CHECKS = "checks";
    private static final String UP = "UP";

    private static Logger log = Logger.getLogger("HealthCheckMonitor");
    private static ObjectMapper oMapper = new ObjectMapper();

    @Inject
    @RestClient
    HealthCheckClient hClient;

    public boolean sitRep() throws JsonMappingException, JsonProcessingException {

        String healthJson = hClient.getHealth();
        JsonNode jNode = oMapper.readTree(healthJson);
        String status = jNode.get(STATUS).asText();
        log.debug("*********** status = "+status);
        if(!UP.equals(status)){
            log.error("sitRep() healthJson = "+healthJson);
            return false;
        }else {
            return true;
        }
    }
    
}
