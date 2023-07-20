package org.acme.apps;

import java.lang.management.MemoryUsage;
import java.net.URL;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.Map.Entry;

import jakarta.ws.rs.core.Response;

import org.jboss.logging.Logger;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;

import ai.djl.Application;
import ai.djl.Device;
import ai.djl.engine.Engine;
import ai.djl.ndarray.types.Shape;
import ai.djl.nn.Block;
import ai.djl.nn.BlockList;
import ai.djl.nn.Parameter;
import ai.djl.nn.ParameterList;
import ai.djl.repository.Artifact;
import ai.djl.repository.zoo.ModelZoo;
import ai.djl.repository.zoo.ZooModel;
import ai.djl.util.Pair;
import ai.djl.util.PairList;
import ai.djl.util.cuda.CudaUtils;
import io.smallrye.mutiny.Uni;

public class BaseResource {

    private static final Logger log = Logger.getLogger("BaseResource");

    private String engineName;

    private ObjectMapper oMapper;

    private Engine engine;

    protected boolean continueToPredict = false;

    public void start() {

        Device gpuDevice = Device.gpu();  // Returns default GPU device
        if(gpuDevice != null)
            log.info("Found default GPU device: "+gpuDevice.getDeviceId());
        else
            log.warn("NO DEFAULT GPU DEVICE FOUND!!!!");

        Set<String> engines = Engine.getAllEngines();
        for(String engine : engines){
            log.info("engine = "+engine);
        }

        engine = Engine.getInstance();
        engineName = engine.getEngineName();
        log.infov("detect() defaultEngineName = {0}, runtime engineName = {1}", Engine.getDefaultEngineName(), engineName);

        oMapper = new ObjectMapper();

    }

    public ObjectMapper getObjectMapper() {
        return oMapper;
    }

    public String getEngineName() {
        return engineName;
    }

    public Uni<Response> logGPUDebug() {

        Engine.debugEnvironment();
        Response eRes = Response.status(Response.Status.OK).entity("Check Logs\n").build();
        return Uni.createFrom().item(eRes);
    }

    public Uni<Response> getGpuCount() {

        Response eRes = Response.status(Response.Status.OK).entity(Engine.getInstance().getGpuCount()).build();
        return Uni.createFrom().item(eRes);
    }

    public Uni<Response> getGpuMemory() {

        Device dObj = Engine.getInstance().defaultDevice();
        long gpuRAM = 0L;
        if(dObj.isGpu()){
            MemoryUsage mem = CudaUtils.getGpuMemory(dObj);
            gpuRAM = mem.getMax();
        }
        Response eRes = Response.status(Response.Status.OK).entity(gpuRAM).build();
        return Uni.createFrom().item(eRes);
    }

    public Uni<Response> listDJLModelZooAppSignatures() {
        
        Map<Application, List<Artifact>> models;
        Response eRes = null;
        try {
            ObjectNode rNode = oMapper.createObjectNode();
            models = ModelZoo.listModels();
            Set<Entry<Application, List<Artifact>>> eSets = models.entrySet();
            for(Entry<Application, List<Artifact>> entryS : eSets) {
                Application app = entryS.getKey();
                ArrayNode artNode = rNode.putArray(app.getPath());
                List<Artifact> artifacts = entryS.getValue();
                for(Artifact aObj : artifacts){
                    ObjectNode secondNode = oMapper.createObjectNode();
                    ArrayNode propNode = secondNode.putArray(aObj.getName() + " , "+aObj.getVersion());

                    Map<String, String> props = aObj.getProperties();
                    for(Entry<String, String> eObj : props.entrySet()) {
                        propNode.add(eObj.getKey()+":"+eObj.getValue());
                    }
                    artNode.add(secondNode);
                }
            }
            String modelsJson = rNode.toPrettyString();
            eRes = Response.status(Response.Status.OK).entity(modelsJson).build();
        } catch (Exception e) {
            e.printStackTrace();
            eRes = Response.status(Response.Status.INTERNAL_SERVER_ERROR).entity(e.getMessage()).build();
        }
        return Uni.createFrom().item(eRes);
    }

    public Uni<Response> listAppModelInputsAndOutputs(ZooModel<?,?> appModel) {
        Response eRes = null;
        try {
            if(appModel == null)
                throw new Exception("appModel is null");
                
            String appModelName = appModel.getName();
            String appModelPath = appModel.getModelPath().toAbsolutePath().toString();
            ObjectNode rNode = oMapper.createObjectNode();
            rNode.put("modelName",appModelName);
            rNode.put("appModelPath", appModelPath);

            PairList<String, Shape> pListInput = appModel.describeInput();
            ArrayNode inputNode = rNode.putArray("input");
            if(pListInput != null && !pListInput.isEmpty()){

                // DJL is throwing a NullPointerException when executing on ImageClassification / ImageDetection models
                try {
                    for(Entry<String, Shape> ePair : pListInput.toMap().entrySet()) {
            
                        Shape sObj = ePair.getValue();
                        inputNode.add(ePair.getKey() +","+ sObj.toString());
                       
                    }
                }catch(NullPointerException n){
                    n.printStackTrace();
                }
            
            }

            PairList<String, Shape> pListOutput = appModel.describeOutput();
            ArrayNode outputNode = rNode.putArray("output");
            if(pListOutput != null && !pListOutput.isEmpty()){

                // DJL is throwing a NullPointerException when executing on ImageClassification / ImageDetection models
                try {
                    for(Entry<String, Shape> ePairO : pListOutput.toMap().entrySet()) {
                        Shape sObj = ePairO.getValue();
                        outputNode.add(ePairO.getKey() +","+ sObj.toString());
                    }
                }catch(NullPointerException n){
                    n.printStackTrace();
                }
            }

            String[] aNames = appModel.getArtifactNames();
            ArrayNode artifactNode = rNode.putArray("artifacts");
            for(String aName: aNames) {
                URL artifact = appModel.getArtifact(aName);
                artifactNode.add(artifact.toString());
            }

            Block appBlock = appModel.getBlock();

            BlockList blocks = appBlock.getChildren();
            ArrayNode blockNode = rNode.putArray("blockList");
            for(Pair<String, Block> pair : blocks) {
                Block block = pair.getValue();
                blockNode.add(pair.getKey());
            }

            /*  This is unsupported in DJL
            ParameterList pList = appBlock.getParameters(); //appBlock.getDirectParameters();
            ArrayNode paramNode = rNode.putArray("parameterList");
            for(Pair<String, Parameter> pair : pList) {
                Parameter param = pair.getValue();
                paramNode.add(pair.getKey()+","+param.getName());
            }
            */

            String modelsJson = rNode.toPrettyString();
            eRes = Response.status(Response.Status.OK).entity(modelsJson).build();
        } catch (Exception e) {
            e.printStackTrace();
            eRes = Response.status(Response.Status.INTERNAL_SERVER_ERROR).entity(e.getMessage()).build();
        }
        return Uni.createFrom().item(eRes);

    }
    
}
