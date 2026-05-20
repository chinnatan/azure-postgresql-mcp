# Azure Database for PostgreSQL MCP Server (Preview)

[ภาษาไทย](README.th.md)

A [Model Context Protocol (MCP)](https://modelcontextprotocol.io/introduction) Server that let’s your AI models talk to data hosted in Azure Database for PostgreSQL according to the MCP standard! 

By utilizing this server, you can effortlessly connect any AI application that supports MCP to your PostgreSQL flexible server (using either PostgreSQL password-based authentication or Microsoft Entra authentication methods), enabling you to provide your business data as meaningful context in a standardized and secure manner.

This server exposes the following tools, which can be invoked by MCP Clients in your AI agents, AI applications or tools like Claude Desktop and Visual Studio Code:

- **List all databases** in your Azure Database for PostgreSQL flexible server instance.
- **List all tables** in a database along with their schema information.
- **Execute read queries** to retrieve data from your database.
- **Insert or update records** in your database.
- **Create a new table or drop an existing table** in your database.
- **List Azure Database for PostgreSQL flexible server configuration**, including its PostgreSQL version, and compute and storage configurations. *
- Retrieve specific **server parameter values.** *
  
_*Available when using Microsoft Entra authentication method_

## Getting Started

### Prerequisites

- Either [Python](https://www.python.org/downloads/) 3.10 or above **or** [Docker](https://docs.docker.com/get-docker/) (Docker Engine or Docker Desktop) if you want to run the MCP server in a container without installing Python dependencies on the host.
- An Azure Database for PostgreSQL flexible server instance with a database containing your business data. For instructions on creating a flexible instance, setting up a database, and connecting to it, please refer to this [quickstart guide](https://learn.microsoft.com/azure/postgresql/flexible-server/quickstart-create-server).
- An MCP Client application or tool such as [Claude Desktop](https://claude.ai/download) or [Visual Studio Code](https://code.visualstudio.com/download).

### Installation

1. Clone the `azure-postgresql-mcp` repository:

    ```
    git clone https://github.com/Azure-Samples/azure-postgresql-mcp.git
    cd azure-postgresql-mcp
    ```

    Alternatively, you can download only the `azure_postgresql_mcp.py` file to your working folder.

2.	Create a virtual environment:

    Windows cmd.exe:
  	```
    python -m venv azure-postgresql-mcp-venv
    .\azure-postgresql-mcp-venv\Scripts\activate.bat
    ```
    Windows Powershell:
  	```
    python -m venv azure-postgresql-mcp-venv
    .\azure-postgresql-mcp-venv\Scripts\Activate.ps1
    ```
    Linux and MacOS:
  	```
    python -m venv azure-postgresql-mcp-venv
    source ./azure-postgresql-mcp-venv/bin/activate 
    ```

4. Install the dependencies:

    ```
    pip install mcp[cli]
    pip install psycopg[binary]
    pip install azure-mgmt-postgresqlflexibleservers
    pip install azure-identity
    ```

### Running with Docker

You can build and run the MCP server in a container so that Python packages are installed only inside the image, not on your machine.

#### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (Docker Engine 20.10+ or Docker Desktop).
- Network access from the container to your Azure Database for PostgreSQL instance (firewall rules, private endpoints, etc., must allow the Docker host’s outbound traffic).

#### Build the image

From the repository root (the directory that contains the `Dockerfile`):

```bash
docker build -t azure-postgresql-mcp:local .
```

This produces an image tagged `azure-postgresql-mcp:local`. Use any tag you prefer; the examples below assume that name.

#### Why `docker run -i` matters

The MCP server communicates over **stdio** (standard input/output). You must run the container with **interactive stdin** enabled:

- Use `docker run -i` (and typically `--rm` to remove the container when the client exits).

Without `-i`, the MCP client cannot talk to the server process.

#### Environment variables

Use the same variables as for a local Python run:

- **Password authentication:** `PGHOST`, `PGUSER`, `PGPASSWORD`, and optionally `PGDATABASE` (if your client or workflow expects it).
- **Microsoft Entra:** see [Using Microsoft Entra authentication method](#using-microsoft-entra-authentication-method). You can pass the same `env` values using repeated `-e` / `--env` flags on `docker run`.

For Microsoft Entra inside Docker, `DefaultAzureCredential` must be able to obtain credentials (for example, environment variables for a service principal, or a mounted Azure CLI login — see the note below).

#### Use the MCP Server with Claude Desktop (Docker)

1. Build the image (see [Build the image](#build-the-image)).
2. In Claude Desktop, open **Settings → Developer → Edit Config** and add or merge a server entry. Example using password authentication:

    ```json
    {
        "mcpServers": {
            "azure-postgresql-mcp": {
                "command": "docker",
                "args": [
                    "run",
                    "-i",
                    "--rm",
                    "-e", "PGHOST=<Fully qualified name of your Azure Database for PostgreSQL instance>",
                    "-e", "PGUSER=<Your Azure Database for PostgreSQL username>",
                    "-e", "PGPASSWORD=<Your password>",
                    "-e", "PGDATABASE=<Your database name>",
                    "azure-postgresql-mcp:local"
                ]
            }
        }
    }
    ```

    On Windows, if `docker` is not on the PATH that Claude Desktop sees, use the full path to `docker.exe` in `"command"` (for example, under Docker Desktop’s installation directory).

3. Restart Claude Desktop.

**Microsoft Entra (Docker):** Pass the same variables as in [Using Microsoft Entra authentication method](#using-microsoft-entra-authentication-method) with additional `-e` entries (for example `AZURE_USE_AAD`, `AZURE_SUBSCRIPTION_ID`, `AZURE_RESOURCE_GROUP`). If you rely on Azure CLI login on the host, you can mount the CLI’s Azure directory into the container (paths vary by OS; Linux/macOS example):

```text
-v ~/.azure:/root/.azure:ro
```

Add that string to the `"args"` array after `"run", "-i", "--rm",` and before the `-e` flags. The container runs as root, so the credential directory inside the container is `/root/.azure`. Adjust if you use a non-root user in a custom image.

#### Use the MCP Server with Visual Studio Code (Docker)

1. Build the image (see [Build the image](#build-the-image)).
2. Open **Settings**, search for **MCP**, and edit `settings.json`. Example:

    ```json
    {
        "mcp": {
            "inputs": [],
            "servers": {
                "azure-postgresql-mcp": {
                    "command": "docker",
                    "args": [
                        "run",
                        "-i",
                        "--rm",
                        "-e", "PGHOST=<Fully qualified name of your Azure Database for PostgreSQL instance>",
                        "-e", "PGUSER=<Your Azure Database for PostgreSQL username>",
                        "-e", "PGPASSWORD=<Your password>",
                        "-e", "PGDATABASE=<Your database name>",
                        "azure-postgresql-mcp:local"
                    ]
                }
            }
        }
    }
    ```

3. Use Copilot Chat in Agent mode and select the MCP tools as described in the VS Code section above.

#### Optional: manual smoke test

To confirm the image starts (the process will wait for MCP traffic on stdio):

```bash
docker run -i --rm -e PGHOST=example.postgres.database.azure.com -e PGUSER=user -e PGPASSWORD=pass azure-postgresql-mcp:local
```

Stop with Ctrl+C. This does not validate database connectivity unless the variables point to a real server.

### Use the MCP Server with Claude Desktop

Watch the following demo video or read on for detailed instructions.



https://github.com/user-attachments/assets/d45da132-46f0-48ac-a1b9-3b1b1b8fd638



1. In the Claude Desktop app, navigate to the “Settings” pane, select the “Developer” tab and click on “Edit Config”.
2. Open the `claude_desktop_config.json` file and add the following configuration to the "mcpServers" section to configure the Azure Database for PostgreSQL MCP server:

    ```json
    {
        "mcpServers": {
            "azure-postgresql-mcp": {
                "command": "<path to the virtual environment>\\azure-postgresql-mcp-venv\\Scripts\\python",
                "args": [
                    "<path to azure_postgresql_mcp.py file>\\azure_postgresql_mcp.py"
                ],
                "env": {
                    "PGHOST": "<Fully qualified name of your Azure Database for PostgreSQL instance>",
                    "PGUSER": "<Your Azure Database for PostgreSQL username>",
                    "PGPASSWORD": "<Your password>",
                    "PGDATABASE": "<Your database name>"
                }
            }        
        }
    }
    ```
    **Note**: Here, we use password-based authentication to connect the MCP Server to Azure Database for PostgreSQL for testing purposes only. However, we recommend using Microsoft Entra authentication. Please refer to [these instructions](#using-microsoft-entra-authentication-method) for guidance.
3. Restart the Claude Desktop app.
4. Upon restarting, you should see a hammer icon at the bottom of the input box. Selecting this icon will display the tools provided by the MCP Server.

You are now all set to start interacting with your data using natural language queries through Claude Desktop!

### Use the MCP Server with Visual Studio Code

Watch the following demo video or read on for detailed instructions.



https://github.com/user-attachments/assets/12328e84-7045-4e3c-beab-4936d7a20c21



1. In Visual Studio Code, navigate to “File”, select “Preferences” and then choose “Settings”.
2. Search for “MCP” and select “Edit in settings.json”.
3. Add the following configuration to the “mcp” section of the `settings.json` file:

    ```JSON
    {
        "mcp": {
            "inputs": [],
            "servers": {
                "azure-postgresql-mcp": {
                    "command": "<path to the virtual environment>\\azure-postgresql-mcp-venv\\Scripts\\python",
                    "args": [
                        "<path to azure_postgresql_mcp.py file>\\azure_postgresql_mcp.py"
                    ],
                    "env": {
                        "PGHOST": "<Fully qualified name of your Azure Database for PostgreSQL instance>",
                        "PGUSER": "<Your Azure Database for PostgreSQL username>",
                        "PGPASSWORD": "<Your password>",
                        "PGDATABASE": "<Your database name>"
                    }
                }
            }
        }
    }
    ```
    **Note**: Here, we use password-based authentication to connect the MCP Server to Azure Database for PostgreSQL for testing purposes only. However, we recommend using Microsoft Entra authentication. Please refer to [these instructions](#using-microsoft-entra-authentication-method) for guidance.
4. Select the “Copilot” status icon in the upper-right corner to open the GitHub Copilot Chat window. 
5. Choose “Agent mode” from the dropdown at the bottom of the chat input box.
5. Click on “Select Tools” (hammer icon) to view the Tools exposed by the MCP Server.

You are now all set to start interacting with your data using natural language queries through VS Code!

## Using Microsoft Entra authentication method

To Microsoft Entra authentication method (recommended) to connect your MCP Server to Azure Database for PostgreSQL, update the MCP Server configuration in `claude_desktop_config.json` file \(Claude Desktop\) and `settings.json` \(Visual Studio Code\) with the following code:

```json
"azure-postgresql-mcp": {
    "command": "<path to the virtual environment>\\azure-postgresql-mcp-venv\\Scripts\\python",
    "args": [
        "<path to azure_postgresql_mcp.py file>\\azure_postgresql_mcp.py"
    ],
    "env": {
        "PGHOST": "<Fully qualified name of your Azure Database for PostgreSQL instance>",
        "PGUSER": "<Your Microsoft Entra ID username or the resource name of your Azure resource with a system-assigned identity or the identity name>",
        "AZURE_USE_AAD": "True",
        "AZURE_SUBSCRIPTION_ID": "<Your Azure subscription ID>",
        "AZURE_RESOURCE_GROUP": "<Your Resource Group that contains the Azure Database for PostgreSQL instance>"
    }
}
```

## Verifying your setup

Use the steps below to confirm the server, database access, and MCP integration.

### 1. Unit tests (no Azure database required)

After installing dependencies and `pytest`:

```bash
pip install pytest
PYTHONPATH=src pytest --color=yes -v
```

All tests should pass. This validates Python code with mocks; it does **not** connect to Azure. See [tests/README.md](tests/README.md).

### 2. Database connectivity (password authentication)

Confirm your machine (or Docker host) can reach the server and that credentials work. Azure Database for PostgreSQL typically requires TLS. Example using [psql](https://www.postgresql.org/docs/current/app-psql.html):

```bash
export PGHOST="<your-server>.postgres.database.azure.com"
export PGUSER="<user>"
export PGPASSWORD="<password>"
psql "host=$PGHOST port=5432 dbname=postgres user=$PGUSER password=$PGPASSWORD sslmode=require" -c "SELECT 1"
```

You should see a result row with `1`. If this fails, fix firewall rules, networking, or credentials before debugging MCP.

### 3. MCP Inspector (end-to-end MCP + live database)

The [MCP Inspector](https://modelcontextprotocol.io/docs/tools/inspector) exercises the MCP protocol and lets you call tools from a browser. Install [Node.js](https://nodejs.org/) ^22.7.5 or later (`node -v` to verify).

**Local Python server** (repository root, virtual environment activated, dependencies installed):

```bash
npx -y @modelcontextprotocol/inspector \
  -e PGHOST="<your-server>.postgres.database.azure.com" \
  -e PGUSER="<user>" \
  -e PGPASSWORD="<password>" \
  python src/azure_postgresql_mcp.py
```

**Docker** (after [building the image](#build-the-image)):

```bash
npx -y @modelcontextprotocol/inspector \
  docker run -i --rm \
  -e PGHOST="<your-server>.postgres.database.azure.com" \
  -e PGUSER="<user>" \
  -e PGPASSWORD="<password>" \
  azure-postgresql-mcp:local
```

Open the URL printed in the terminal (often `http://localhost:6274`). In the UI, connect to the server, open **Tools**, and run **`get_databases`** (or another tool). A successful response means the MCP process, protocol, and PostgreSQL access are working together.

For Microsoft Entra, add the same environment variables as in [Using Microsoft Entra authentication method](#using-microsoft-entra-authentication-method) using extra `-e` flags, and ensure `DefaultAzureCredential` can obtain credentials on that host (for Docker, see the note about mounting `~/.azure` when using Azure CLI login).

### 4. Your MCP client (Claude Desktop / VS Code)

After client configuration:

- **Claude Desktop:** A hammer icon appears near the chat input; open it to list tools (for example `get_databases`).
- **VS Code:** In GitHub Copilot Chat **Agent** mode, use **Select Tools** (hammer) and confirm the same tools appear.

Run a simple tool from the client. If the Inspector succeeds but the client does not, check executable paths, environment variables, and whether `docker` or `python` is on the `PATH` the application sees.

## Contributing
The Azure Database for PostgreSQL MCP Server is currently in Preview. As we continue to develop and enhance its features, we welcome all contributions! For more details, see the [CONTRIBUTING.md](CONTRIBUTING.md) file.

## License
This project is licensed under the MIT License. For more details, see the [LICENSE](LICENSE.md) file.
