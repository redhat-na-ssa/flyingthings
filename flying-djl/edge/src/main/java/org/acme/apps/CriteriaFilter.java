package org.acme.apps;

import java.util.Map;

import io.smallrye.config.ConfigMapping;

@ConfigMapping(prefix = "org.acme.objectdetection.criteria.filters")
public interface CriteriaFilter {
    Map<String, String> pytorch();
    Map<String, String> tensorflow();
    Map<String, String> mxnet();

}
