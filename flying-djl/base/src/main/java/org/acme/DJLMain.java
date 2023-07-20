package org.acme;


import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.event.Observes;
import jakarta.enterprise.inject.Instance;
import jakarta.inject.Inject;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import org.acme.apps.IApp;

import io.smallrye.mutiny.Uni;

import org.jboss.logging.Logger;

public abstract class DJLMain {

    Logger log = Logger.getLogger("DJLMain");

    private Instance<IApp> djlApp;

    public void setDjlApp(Instance<IApp> x){
        this.djlApp = x;
    }

    @POST
    @Path("/predict")
    @Produces(MediaType.APPLICATION_JSON)
    public Uni<Response> predict() {
        return djlApp.get().predict();
    }

    @DELETE
    @Path("/stopPrediction")
    @Produces(MediaType.APPLICATION_JSON)
    public Uni<Response> stopPrediction() {
        return djlApp.get().stopPrediction();
    }

    @GET
    @Path("/logGPUDebug")
    @Produces(MediaType.TEXT_PLAIN)
    public Uni<Response> logGPUDebug() {
        return djlApp.get().logGPUDebug();
    }

    @GET
    @Path("/gpucount")
    @Produces(MediaType.TEXT_PLAIN)
    public Uni<Response> getGpuCount() {
        return djlApp.get().getGpuCount();
    }

    @GET
    @Path("/gpumemory")
    @Produces(MediaType.APPLICATION_JSON)
    public Uni<Response> getGpuMemory() {
        return djlApp.get().getGpuMemory();
    }


    @GET
    @Path("/listDJLModelZooAppSignatures")
    @Produces(MediaType.APPLICATION_JSON)
    public Uni<Response> listDJLModelZooAppSignatures() {
        return djlApp.get().listDJLModelZooAppSignatures();
    }


    @GET
    @Path("/listAppModelInputsAndOutputs")
    @Produces(MediaType.APPLICATION_JSON)
    public Uni<Response> listAppModelInputsAndOutputs() {
        
        return djlApp.get().listAppModelInputsAndOutputs(djlApp.get().getAppModel());
    }
    
}
