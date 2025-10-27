# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Docker MCP Server implementation that exposes Docker commands as Model Context Protocol (MCP) tools. It's built on the `mcp_mediator` framework and automatically generates MCP tools from Docker client service methods.

## Build Commands

### Standard Maven Build
```bash
mvn clean compile package
```
This creates a JAR file: `target/mcp-mediator-implementation-docker-[version].jar`

### Native Image Build
```bash
native-image -jar mcp-mediator-implementation-docker-[version].jar
```
Creates a standalone executable file for better performance.

### Running the Server
```bash
java -jar docker-mcp-server.jar \
  --docker-host=tcp://localhost:2376 \
  --tls-verify \
  --cert-path=/etc/docker/certs \
  --server-name=my-server \
  --server-version=1.0.0 \
  --max-connections=150 \
  --docker-config=/custom/docker/config
```

## Architecture

### Core Components

1. **DockerMcpServer** (`src/main/java/io/github/makbn/mcp/mediator/docker/server/DockerMcpServer.java`)
   - Main entry point and CLI argument parsing
   - Initializes Docker client and MCP Mediator
   - Configures server settings (name, version, connections)

2. **DockerClientService** (`src/main/java/io/github/makbn/mcp/mediator/docker/internal/DockerClientService.java`)
   - Core service class containing all Docker operations
   - Methods annotated with `@McpTool` are automatically exposed as MCP tools
   - Uses docker-java library for Docker communication

3. **MCP Mediator Integration**
   - Uses `mcp_mediator` framework to automatically convert service methods to MCP tools
   - Automatic tool generation based on method signatures and annotations
   - Supports both annotated and non-annotated methods

### Docker Configuration

The server connects to Docker daemon with configurable options:
- **Docker Host**: Default `unix:///var/run/docker.sock`, supports TCP with TLS
- **TLS Support**: Optional TLS verification with certificate paths
- **Connection Pooling**: Configurable max connections (default: 100)
- **Custom Config**: Override default Docker config directory

### MCP Tool Generation

The system automatically generates MCP tools from DockerClientService methods:
- Each `@McpTool` annotated method becomes an MCP tool
- Tool names and descriptions are auto-generated but can be customized
- Parameters are inferred from method signatures
- Returns JSON-serializable results

## Testing

```bash
mvn test
```

Test files are located in `src/test/java/io/github/makbn/mediator/docker/handler/`.

## Development Notes

### Adding New Docker Commands
1. Add new methods to `DockerClientService` class
2. Annotate with `@McpTool` if custom metadata is needed
3. Method parameters become tool parameters automatically
4. Return types should be JSON-serializable

### Configuration Files
- **pom.xml**: Maven configuration with GraalVM native image support
- **dockerfile**: Container deployment setup using mcp-streamable-http-bridge
- **settings.json**: HTTP bridge configuration for Docker MCP server

### Environment Variables
- `DOCKER_MCP_LOG_LEVEL`: Controls logging verbosity (TRACE, DEBUG, INFO, etc.)
- `DOCKER_MCP_LOG_FILE`: Custom log file path (default: logs/docker_mcp_server.log)

### Key Dependencies
- **docker-java**: Docker client library (3.5.0)
- **mcp-mediator-core**: Core MCP framework
- **commons-cli**: Command line argument parsing
- **logback**: Logging framework

The project is part of the larger `mcp_mediator` ecosystem and is maintained as a Git subtree module for independent versioning while keeping integration with the main mono-repo.