# Docker MCP Server

This module provides an implementation of a **Model Context Protocol** MCP server for Docker commands, powered by the [
`mcp_mediator`](https://github.com/makbn/mcp_mediator) core framework.
The Docker MCP Server utilizes the **automatic server generation** feature of MCP Mediator to expose existing Docker
commands as MCP Tools.
Each command is optionally annotated with `@McpTool` along with a minimal description to enhance tool discoverability
and usability.

👉 See the full list of supported commands [here](#supported-docker-commands-as-mcp-server-tools).

![Docker MCP Server](./.github/static/docker_mcp_server_inspect.png)


> [!IMPORTANT]  
> This is part of `mcp_mediator`
> project: [https://github.com/makbn/docker_mcp_server](https://github.com/makbn/docker_mcp_server)
> To build or modify, clone the parent repository:
`git clone --recurse-submodules https://github.com/makbn/docker_mcp_server.git`

### Usage Examples

```shell
java -jar docker-mcp-server.jar \
  --docker-host=tcp://localhost:2376 \
  --tls-verify \
  --cert-path=/etc/docker/certs \
  --server-name=my-server \
  --server-version=1.0.0 \
  --max-connections=150 \
  --docker-config=/custom/docker/config
```

To run Docker MCP Server with Claude Desktop with `java -jar`:

```yaml
{
  "mcpServers": {
    "my_java_mcp_server": {
      "command": "java",
      "args": [
        "-jar",
        "docker-mcp-server.jar"
        "--docker-host=tcp://localhost:2376",
        "--tls-verify", # not required
        "--cert-path=/etc/docker/certs", # required only if --tls-verify is available
        "--server-name=my-docker-mcp-server",
        "--server-version=1.0.0",
        "--max-connections=150",
        "--docker-config=/custom/docker/config"
      ]
    }
  }
}
```

Or create the native image (see the steps below) and use the standalone application:

```yaml
{
  "mcpServers": {
    "my_java_mcp_server": {
      "command": "docker-mcp-server-executable",
      "args": [
        "--docker-host=tcp://localhost:2376" // rest of args
      ]
    }
  }
}
```

### How to Build

To build the executable:

```bash
mvn clean compile package
```

This command creates a jar file under `target` folder `mcp-mediator-implementation-docker-[version].jar`. You can stop
here and use the jar file and execute it
using `java -jar` command. Or, you can create a standalone executable application using GraalVM native image:

```bash
 native-image -jar mcp-mediator-implementation-docker-[version].jar     
```

and this command creates an executable file: `'mcp-mediator-implementation-docker-[version]` that can be executed.

### Automatically Generate MCP Tools

This project integrates with [`MCP Mediator`](https://github.com/makbn/mcp_mediator) to automatically generate MCP Tools
from existing Docker services.

Each method in the Docker service class can optionally be annotated with `@McpTool` to explicitly define the tool’s *
*name**, **description**, and other metadata.

However, annotation is **not required**—MCP Mediator supports automatic generation for **non-annotated methods** by
inferring details from the method, class, and package names. To enable this behavior, set `createForNonAnnotatedMethods`
to `true`:

```java
DefaultMcpMediator mediator = new DefaultMcpMediator(McpMediatorConfigurationBuilder.builder()
        .createDefault()
        .serverName(serverName)
        .serverVersion(serverVersion)
        .build());

mediator.

registerHandler(McpServiceFactory.create(dockerClientService)
        .

createForNonAnnotatedMethods(true)); // Enables support for non-annotated methods

```

Check `io.github.makbn.mcp.mediator.docker.server.DockerMcpServer` for the full Mcp Mediator configuration.

### Supported CLI Options

| Option              | Description                                                         | Default                       |
|---------------------|---------------------------------------------------------------------|-------------------------------|
| `--docker-host`     | Docker daemon host URI                                              | `unix:///var/run/docker.sock` |
| `--tls-verify`      | Enable TLS verification (used with `--cert-path`)                   | `false`                       |
| `--cert-path`       | Path to Docker TLS client certificates (required if TLS is enabled) | _none_                        |
| `--docker-config`   | Custom Docker config directory                                      | `~/.docker`                   |
| `--server-name`     | Server name for the MCP server                                      | `docker_mcp_server`           |
| `--server-version`  | Server version label                                                | `1.0.0.0`                     |
| `--max-connections` | Maximum number of connections to Docker daemon                      | `100`                         |
| `--help`            | Show usage and available options                                    | _n/a_                         |

Environment variables:

| Option                | Description                                    | Default                      |
|-----------------------|------------------------------------------------|------------------------------|
| `DOCKER_MCP_LOG_LEVEL` | Logging level (`TRACE`, `DEBUG`, `INFO`, etc.) | `DEBUG`                      |
| `DOCKER_MCP_LOG_FILE` | Path to log output file                        | `logs/docker_mcp_server.log` |


### Supported Docker Commands as MCP Server Tools

| MCP Tool Name                                | Description                                    |
|----------------------------------------------|------------------------------------------------|
| docker\_start\_container                     | Start a Docker container by ID.                |
| docker\_stop\_container                      | Stop a Docker container by ID.                 |
| docker\_leave\_swarm                         | Remove a node from Docker Swarm.               |
| docker\_container\_diff                      | Show changes made to a container’s filesystem. |
| docker\_build\_image\_file                   | Build an image from Dockerfile or directory.   |
| docker\_inspect\_volume                      | Get details of a Docker volume.                |
| docker\_remove\_service                      | Remove a Docker service by ID.                 |
| docker\_list\_containers                     | List containers with optional filters.         |
| docker\_inspect\_swarm                       | Inspect Docker Swarm details.                  |
| docker\_push\_image                          | Push image to registry, supports auth.         |
| docker\_copy\_archive\_to\_container         | Copy a tar archive into a running container.   |
| docker\_stats\_container                     | Fetch container stats (CPU, memory, etc.).     |
| docker\_disconnect\_container\_from\_network | Disconnect container from Docker network.      |
| docker\_remove\_container                    | Remove a container, with optional force.       |
| docker\_inspect\_service                     | Inspect a Docker service.                      |
| docker\_remove\_secret                       | Remove a Docker secret by ID.                  |
| docker\_pull\_image                          | Pull image from registry, supports auth.       |
| docker\_inspect\_container                   | Inspect container config and state.            |
| docker\_unpause\_container                   | Unpause a paused container.                    |
| docker\_list\_images                         | List Docker images with optional filters.      |
| docker\_list\_services                       | List all Docker services in the swarm.         |
| docker\_remove\_image                        | Remove an image, with force and prune options. |
| docker\_create\_network                      | Create a Docker network.                       |
| docker\_tag\_image                           | Tag an image with a new repo and tag.          |
| docker\_authenticate                         | Authenticate to Docker registry.               |
| docker\_exec\_command                        | Execute a command inside a container.          |
| docker\_remove\_swarm\_node                  | Remove a swarm node, optionally forcibly.      |
| docker\_search\_images                       | Search Docker Hub for images.                  |
| docker\_list\_networks                       | List all Docker networks.                      |
| docker\_remove\_volume                       | Remove a Docker volume.                        |
| docker\_create\_container                    | Create a container with custom settings.       |
| docker\_remove\_network                      | Remove a Docker network.                       |
| docker\_copy\_archive\_from\_container       | Copy files from a container to the host.       |
| docker\_rename\_container                    | Rename a Docker container.                     |
| docker\_pause\_container                     | Pause a running container.                     |
| docker\_version                              | Get Docker version information.                |
| docker\_list\_swarm\_nodes                   | List all nodes in the Docker swarm.            |
| docker\_log\_container                       | Retrieve logs from a container.                |
| docker\_prune                                | Prune unused Docker resources.                 |
| docker\_inspect\_network                     | Get detailed info about a network.             |
| docker\_kill\_container                      | Send a kill signal to a container.             |
| docker\_top\_container                       | Get running processes in a container.          |
| docker\_list\_volumes                        | List Docker volumes with optional filters.     |
| docker\_update\_swarm\_node                  | Update the config of a swarm node.             |
| docker\_info                                 | Show Docker system-wide info.                  |
| docker\_log\_service                         | Get logs from a Docker service.                |
| docker\_load\_image                          | Load an image from a tar archive.              |
| docker\_list\_tasks                          | Lists the tasks in a Docker Swarm environment. |
| docker\_save\_image                          | Saves a Docker image to a local tar file.      |
| docker\_join\_swarm                          | Joins the node to an existing Swarm cluster.   |
| docker\_create\_volume                       | Creates a new Docker volume.                   |
| docker\_initialize\_swarm                    | Initializes a new Docker Swarm cluster.        |

Work in progress, more to be added.

### DockerClientService Function Coverage

Check the [DockerClientService](./src/main/java/io/github/makbn/mcp/mediator/docker/internal/DockerClientService.java)
class for the full list of available and planned tools (to be implemented)

> [!IMPORTANT]  
> Almost all the MCP Tools' descriptions and names are generated automatically using AI agent!

### 🧩 Repository Structure and Git Subtree Setup

This project is a **Git subtree module** of the parent repository [
`makbn/mcp_mediator`](https://github.com/makbn/mcp_mediator). It is kept in its own repository to support independent
versioning, CI, and release processes, while remaining integrated into the main `mcp_mediator` mono-repo.

### 🔀 Cloning Structure

If you're working in the context of the full `mcp_mediator` system:

```bash
`git clone --recurse-submodules https://github.com/makbn/docker_mcp_server.git`
```

### Contributing

Contributions are welcome! Please feel free to submit a Pull Request. Read this first!

### License

This project is licensed under the GPL3 License—see the LICENSE file for details.

