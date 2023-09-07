package org.acme.apps;

import jakarta.ws.rs.core.Response;

import ai.djl.repository.zoo.ZooModel;
import io.smallrye.mutiny.Uni;

public interface IApp {

    public void startResource();
    public Uni<Response> logGPUDebug();
    public Uni<Response> getGpuCount();
    public Uni<Response> getGpuMemory();
    public Uni<Response> predict();
    public Uni<Response> stopPrediction();
    public Uni<Response> listDJLModelZooAppSignatures();
    public Uni<Response> listAppModelInputsAndOutputs(ZooModel<?,?> appModel);

    public ZooModel<?,?> getAppModel();
  
}
