package org.acme.apps;

import org.eclipse.microprofile.rest.client.annotation.RegisterClientHeaders;
import org.eclipse.microprofile.rest.client.inject.RegisterRestClient;

import io.quarkus.rest.client.reactive.ClientExceptionMapper;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

@RegisterRestClient(configKey="iHealth")
@RegisterClientHeaders
@Path("/")
public interface HealthCheckClient {

    @GET
    @Path("/q/health")
    @Produces(MediaType.APPLICATION_JSON)
    public String getHealth();


     @ClientExceptionMapper
     static RuntimeException toException(Response response) {
         throw new RuntimeException("Remote Exception status: "+response.getStatus());
 
     }
    
}
