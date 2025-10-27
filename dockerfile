# Stage 0: Build mcp_mediator dependency
FROM maven:3.8.4-openjdk-17 AS mcp-mediator-builder

WORKDIR /mcp_mediator

# Download and build mcp_mediator project using gh-proxy for faster access in China
RUN git clone https://gh-proxy.com/https://github.com/makbn/mcp_mediator.git .

# Build mcp_mediator project
RUN mvn clean install -B -DskipTests

# Stage 1: Build the Java application
FROM maven:3.8.4-openjdk-17 AS maven-builder

WORKDIR /app

# Copy pom.xml first for better Docker layer caching
COPY pom.xml .

# Copy the built mcp_mediator JAR from the mcp-mediator-builder stage
RUN mkdir -p /root/.m2/repository/io/github/makbn/mcp_mediator/
COPY --from=mcp-mediator-builder /mcp_mediator/target/*.jar /root/.m2/repository/io/github/makbn/mcp_mediator/

# Download dependencies
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build the application
RUN mvn clean package -B -DskipTests

# Stage 2: Create the final Docker image
FROM docker.cnb.cool/masx200/docker_mirror/mcp-streamable-http-bridge:2.5.1

# Install OpenJDK 17 (Using default-jdk for compatibility with newer Debian versions)
RUN apt-get update && apt-get install -y \
    default-jdk \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME environment variable (auto-detect Java installation)
RUN JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::") && \
    echo "JAVA_HOME=$JAVA_HOME" >> /etc/environment && \
    echo "export JAVA_HOME=$JAVA_HOME" >> /root/.bashrc
ENV JAVA_HOME=/usr/lib/jvm/default-java
ENV PATH=$JAVA_HOME/bin:$PATH

# Verify Java installation
RUN java -version

# Set working directory
WORKDIR /root/docker_mcp_server

# Copy the built JAR from the maven-builder stage
COPY --from=maven-builder /app/target/*.jar /root/docker_mcp_server/docker-mcp-server.jar

# Copy configuration file
# COPY settings.json /root/mcp-streamable-http-bridge/settings.json
COPY settings.json /data/settings.json

# Expose port for HTTP bridge
EXPOSE 3000

# Start the HTTP bridge which will launch the Docker MCP Server
# The bridge will be started by the base image's docker-entrypoint.sh
# We override the CMD to start our specific configuration
CMD ["node", "/root/mcp-streamable-http-bridge/main.js", "--host", "0.0.0.0", "--port", "3000", "--config", "/data/settings.json"]

