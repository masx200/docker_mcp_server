# Stage 0: Clone and setup mcp_mediator parent project
FROM maven:3.8.4-openjdk-17 AS mcp-mediator-builder
COPY settings.xml /usr/share/maven/conf/settings.xml
WORKDIR /build

# Clone mcp_mediator project
RUN git clone https://gh-proxy.com/https://github.com/makbn/mcp_mediator.git .

# Check the parent pom.xml to find the version
RUN cat pom.xml | grep -A 5 -B 5 "revision" || echo "No revision found"

# Set the revision property in the parent pom first (use correct version 1.0.0-SNAPSHOT)
RUN mvn clean install -N -B -DskipTests -Drevision=1.0.0-SNAPSHOT || echo "Failed to install parent pom with version 1.0.0-SNAPSHOT"

# Build mcp-mediator-core and mcp-mediator-api with explicit version
RUN cd mcp-mediator-core && mvn clean install -B -DskipTests -Drevision=1.0.0-SNAPSHOT || echo "Failed to build core module"
RUN cd mcp-mediator-api && mvn clean install -B -DskipTests -Drevision=1.0.0-SNAPSHOT || echo "Failed to build api module"

# Stage 1: Build the Java application
FROM maven:3.8.4-openjdk-17 AS maven-builder
COPY settings.xml /usr/share/maven/conf/settings.xml
WORKDIR /app

# Copy pom.xml first for better Docker layer caching
COPY pom.xml .

# Copy the maven repository from the mcp-mediator-builder stage
COPY --from=mcp-mediator-builder /root/.m2/repository /root/.m2/repository

# Download dependencies
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build the application with explicit revision
RUN mvn clean package -B -DskipTests -Drevision=1.0.0

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

