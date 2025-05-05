package io.github.makbn.mediator.docker.handler;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.github.dockerjava.api.model.SwarmNodeSpec;
import io.github.makbn.mcp.mediator.core.internal.McpMethodSchemaGenerator;
import io.github.makbn.mcp.mediator.docker.internal.DockerClientService;
import org.junit.jupiter.api.Test;

class DockerClientServiceTest {

    @Test
    void testDockerClientService() throws NoSuchMethodException, JsonProcessingException {
        String schema = McpMethodSchemaGenerator.of(new ObjectMapper())
                .generateSchemaForMethod(DockerClientService.class.getMethod("updateSwarmNodeCmd", String.class, SwarmNodeSpec.class));

        System.out.println(schema);
    }

}


