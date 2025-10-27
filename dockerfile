# Stage 1: Build the Java application
FROM maven:3.8.4-openjdk-11 AS maven-builder

WORKDIR /app

# Copy pom.xml first for better Docker layer caching
COPY pom.xml .

# Download dependencies
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build the application
RUN mvn clean package -B -DskipTests

# Stage 2: Create the final Docker image
FROM docker.cnb.cool/masx200/docker_mirror/mcp-streamable-http-bridge:2.5.1

# Install OpenJDK 11
RUN apt-get update && apt-get install -y \
    openjdk-11-jdk \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME environment variable
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

# Verify Java installation
RUN java -version

# Set working directory
WORKDIR /root/docker_mcp_server

# Copy the built JAR from the maven-builder stage
COPY --from=maven-builder /app/target/*.jar /root/docker_mcp_server/docker-mcp-server.jar

# Copy configuration file
COPY settings.json /root/mcp-streamable-http-bridge/settings.json

# Expose port for HTTP bridge
EXPOSE 3000

# Start the HTTP bridge which will launch the Docker MCP Server
# The bridge will be started by the base image's docker-entrypoint.sh
# We override the CMD to start our specific configuration
CMD ["node", "/root/mcp-streamable-http-bridge/main.js", "--host", "0.0.0.0", "--port", "3000" , "--config",       "/data/settings.json"]

