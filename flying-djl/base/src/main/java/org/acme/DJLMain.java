package org.acme;

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

    private IApp djlApp;

    public void setDjlApp(IApp x){
        this.djlApp = x;
    }

    @POST
    @Path("/predict")
    @Produces(MediaType.APPLICATION_JSON)
    public Uni<Response> predict() {
        return djlApp.predict();
    }

    @DELETE
    @Path("/stopPrediction")
    @Produces(MediaType.APPLICATION_JSON)
    public Uni<Response> stopPrediction() {
        return djlApp.stopPrediction();
    }

    @GET
    @Path("/logGPUDebug")
    @Produces(MediaType.TEXT_PLAIN)
    public Uni<Response> logGPUDebug() {
        return djlApp.logGPUDebug();
    }

    @GET
    @Path("/gpucount")
    @Produces(MediaType.TEXT_PLAIN)
    public Uni<Response> getGpuCount() {
        return djlApp.getGpuCount();
    }

    @GET
    @Path("/gpumemory")
    @Produces(MediaType.APPLICATION_JSON)
    public Uni<Response> getGpuMemory() {
        return djlApp.getGpuMemory();
    }


    @GET
    @Path("/listDJLModelZooAppSignatures")
    @Produces(MediaType.APPLICATION_JSON)
    public Uni<Response> listDJLModelZooAppSignatures() {
        return djlApp.listDJLModelZooAppSignatures();
    }


    @GET
    @Path("/listAppModelInputsAndOutputs")
    @Produces(MediaType.APPLICATION_JSON)
    public Uni<Response> listAppModelInputsAndOutputs() {
        
        return djlApp.listAppModelInputsAndOutputs(djlApp.getAppModel());
    }
    
}
