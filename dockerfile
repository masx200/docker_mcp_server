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

# Build mcp-mediator-api first (core depends on api)
RUN cd mcp-mediator-api && mvn clean install -B -DskipTests -Drevision=1.0.0-SNAPSHOT
RUN cd mcp-mediator-core && mvn clean install -B -DskipTests -Drevision=1.0.0-SNAPSHOT

# Verify the artifacts were created
RUN ls -la /root/.m2/repository/io/github/makbn/mcp-mediator-core/1.0.0-SNAPSHOT/ || echo "Core artifacts not found"
RUN ls -la /root/.m2/repository/io/github/makbn/mcp-mediator-api/1.0.0-SNAPSHOT/ || echo "API artifacts not found"

# Stage 1: Build the Java application
FROM maven:3.8.4-openjdk-17 AS maven-builder
COPY settings.xml /usr/share/maven/conf/settings.xml
WORKDIR /app

# Copy pom.xml first for better Docker layer caching
COPY pom-final.xml ./pom.xml

# Replace ${revision} with actual version in pom.xml
RUN sed -i 's/\${revision}/1.0.0-SNAPSHOT/g' pom.xml

# Copy the maven repository from the mcp-mediator-builder stage
COPY --from=mcp-mediator-builder /root/.m2/repository /root/.m2/repository

# Download dependencies (now pom.xml has hardcoded version)
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build the application (now pom.xml has hardcoded version)
RUN mvn clean package -B -DskipTests

# Stage 2: Create the final Docker image
# FROM docker.cnb.cool/masx200/docker_mirror/mcp-streamable-http-bridge:2.5.1
# 压缩镜像之后,不再使用老的镜像

from docker.cnb.cool/masx200/docker_mirror/docker-mcp-server:slim
# Install OpenJDK 17 (Using default-jdk for compatibility with newer Debian versions)
RUN apt-get update && apt-get install -y \
    default-jdk \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Remove unnecessary packages to reduce image size
RUN apt-get remove --purge -y \
    python3 python3-dev python3-pip python3-wheel python3-packaging \
    build-essential gcc g++ make libc6-dev linux-libc-dev dpkg-dev \
    perl perl-modules-5.40 libperl5.40 zlib1g-dev uuid-dev x11proto-dev xtrans-dev \
    libpython3-dev libpython3.13-dev manpages-dev git || true

RUN apt-get autoremove --purge -y && apt-get clean

# Remove documentation, include headers, and static libraries
RUN rm -rf /usr/share/doc/* /usr/share/man/* /usr/include/* \
    /usr/lib/x86_64-linux-gnu/*.a /usr/lib/gcc

# Remove fonts, icons, and themes
RUN rm -rf /usr/share/fonts/* /usr/share/icons/* /usr/share/themes/*

# Remove GUI libraries and X11 dependencies
RUN apt-get remove --purge -y \
    libgtk* libgdk* libglib* libpango* libcairo* libatk* \
    libgdk-pixbuf* libatspi* libx11-6 libxext6 libxrandr2 libxrender1 \
    libxi6 libxtst6 libxxf86vm1 default-jdk default-jre || true

RUN apt-get autoremove --purge -y && apt-get clean

# Install minimal Java JRE (headless)
RUN mkdir -p /usr/share/man/man1 && \
    apt-get update && apt-get install -y --no-install-recommends \
    openjdk-21-jre-headless && \
    dpkg --configure -a && apt-get clean

# Set JAVA_HOME environment variable (auto-detect Java installation)
RUN JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::") && \
    echo "JAVA_HOME=$JAVA_HOME" >> /etc/environment && \
    echo "export JAVA_HOME=$JAVA_HOME" >> /root/.bashrc
ENV JAVA_HOME=/usr/lib/jvm/default-java
ENV PATH=$JAVA_HOME/bin:$PATH

# Verify Java and Node installation
RUN java -version && node --version

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

