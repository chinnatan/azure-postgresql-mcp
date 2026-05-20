# Azure Database for PostgreSQL MCP Server (พรีวิว)

[English](README.md)

[Model Context Protocol (MCP)](https://modelcontextprotocol.io/introduction) Server ที่ให้โมเดล AI ของคุณสื่อสารกับข้อมูลใน Azure Database for PostgreSQL ตามมาตรฐาน MCP

เมื่อใช้เซิร์ฟเวอร์นี้ คุณเชื่อมแอปที่รองรับ MCP กับ PostgreSQL flexible server ได้ทั้งการยืนยันตัวตนด้วยรหัสผ่าน PostgreSQL หรือ Microsoft Entra เพื่อนำข้อมูลธุรกิจมาเป็นบริบทให้ AI อย่างเป็นมาตรฐานและปลอดภัย

เซิร์ฟเวอร์นี้เปิดเครื่องมือ (tools) ต่อไปนี้ให้ MCP Client เรียกใช้จาก AI agent, แอป AI หรือเครื่องมืออย่าง Claude Desktop และ Visual Studio Code:

- **แสดงรายการฐานข้อมูลทั้งหมด** บนอินสแตนซ์ Azure Database for PostgreSQL flexible server
- **แสดงรายการตารางทั้งหมด** ในฐานข้อมูลพร้อมข้อมูลสคีมา
- **รันคิวรีแบบอ่านอย่างเดียว** เพื่อดึงข้อมูล
- **แทรกหรืออัปเดตแถว** ในฐานข้อมูล
- **สร้างตารางใหม่หรือลบตาราง** ในฐานข้อมูล
- **แสดงการตั้งค่าเซิร์ฟเวอร์** Azure Database for PostgreSQL flexible server รวมถึงเวอร์ชัน PostgreSQL และการคอนฟิก compute / storage *
- ดึงค่า **พารามิเตอร์ของเซิร์ฟเวอร์** ที่ระบุ *

_*ใช้ได้เมื่อยืนยันตัวตนด้วย Microsoft Entra_

## การเริ่มต้นใช้งาน

### สิ่งที่ต้องมี

- [Python](https://www.python.org/downloads/) 3.10 ขึ้นไป **หรือ** [Docker](https://docs.docker.com/get-docker/) (Docker Engine หรือ Docker Desktop) หากต้องการรัน MCP server ใน container โดยไม่ติดตั้งแพ็กเกจ Python บนเครื่อง host
- อินสแตนซ์ Azure Database for PostgreSQL flexible server และฐานข้อมูลที่มีข้อมูลธุรกิจของคุณ ดูวิธีสร้างเซิร์ฟเวอร์และเชื่อมต่อได้ที่ [คู่มือ quickstart](https://learn.microsoft.com/azure/postgresql/flexible-server/quickstart-create-server)
- แอปหรือเครื่องมือ MCP Client เช่น [Claude Desktop](https://claude.ai/download) หรือ [Visual Studio Code](https://code.visualstudio.com/download)

### การติดตั้ง

1. โคลน repository `azure-postgresql-mcp`:

    ```
    git clone https://github.com/Azure-Samples/azure-postgresql-mcp.git
    cd azure-postgresql-mcp
    ```

    หรือดาวน์โหลดเฉพาะไฟล์ `azure_postgresql_mcp.py` ไปยังโฟลเดอร์ทำงานของคุณ

2. สร้าง virtual environment:

    Windows cmd.exe:
    ```
    python -m venv azure-postgresql-mcp-venv
    .\azure-postgresql-mcp-venv\Scripts\activate.bat
    ```
    Windows PowerShell:
    ```
    python -m venv azure-postgresql-mcp-venv
    .\azure-postgresql-mcp-venv\Scripts\Activate.ps1
    ```
    Linux และ macOS:
    ```
    python -m venv azure-postgresql-mcp-venv
    source ./azure-postgresql-mcp-venv/bin/activate
    ```

3. ติดตั้ง dependencies:

    ```
    pip install mcp[cli]
    pip install psycopg[binary]
    pip install azure-mgmt-postgresqlflexibleservers
    pip install azure-identity
    ```

### รันด้วย Docker

คุณสามารถ build และรัน MCP server ใน container เพื่อให้แพ็กเกจ Python อยู่เฉพาะใน image ไม่ต้องติดตั้งบนเครื่องของคุณ

#### สิ่งที่ต้องมี (Docker)

- [Docker](https://docs.docker.com/get-docker/) (Docker Engine 20.10+ หรือ Docker Desktop)
- เครือข่ายจาก container ไปยัง Azure Database for PostgreSQL ของคุณได้ (กฎไฟร์วอลล์, private endpoint ฯลฯ ต้องอนุญาตทราฟฟิกขาออกจาก host ที่รัน Docker)

<a id="build-docker-image"></a>
#### สร้าง image

จากโฟลเดอร์รากของ repository (โฟลเดอร์ที่มี `Dockerfile`):

```bash
docker build -t azure-postgresql-mcp:local .
```

จะได้ image ที่ tag เป็น `azure-postgresql-mcp:local` คุณใช้ tag อื่นก็ได้ ตัวอย่างด้านล่างสมมติชื่อนี้

#### ทำไมต้องใช้ `docker run -i`

MCP server สื่อสารผ่าน **stdio** (standard input/output) จึงต้องรัน container โดยเปิด **interactive stdin**:

- ใช้ `docker run -i` (และมักใส่ `--rm` เพื่อลบ container เมื่อ client ปิด)

ถ้าไม่มี `-i` MCP client จะคุยกับเซิร์ฟเวอร์ไม่ได้

#### ตัวแปรสภาพแวดล้อม

ใช้ชุดเดียวกับตอนรันด้วย Python บนเครื่อง:

- **ยืนยันตัวตนด้วยรหัสผ่าน:** `PGHOST`, `PGUSER`, `PGPASSWORD` และถ้าจำเป็น `PGDATABASE` (ถ้า client หรือขั้นตอนงานของคุณต้องการ)
- **Microsoft Entra:** ดู [วิธีการยืนยันตัวตนด้วย Microsoft Entra](#using-microsoft-entra-th) ส่งค่า `env` เดียวกันได้โดยใช้ `-e` / `--env` ซ้ำบน `docker run`

สำหรับ Microsoft Entra ใน Docker `DefaultAzureCredential` ต้องดึง credential ได้ (เช่น ตัวแปรสำหรับ service principal หรือ mount โฟลเดอร์จาก `az login` — ดูหมายเหตุด้านล่าง)

#### ใช้ MCP Server กับ Claude Desktop (Docker)

1. สร้าง image (ดู [สร้าง image](#build-docker-image))
2. ใน Claude Desktop เปิด **Settings → Developer → Edit Config** แล้วเพิ่มหรือรวม entry ของเซิร์ฟเวอร์ ตัวอย่างใช้รหัสผ่าน:

    ```json
    {
        "mcpServers": {
            "azure-postgresql-mcp": {
                "command": "docker",
                "args": [
                    "run",
                    "-i",
                    "--rm",
                    "-e", "PGHOST=<ชื่อ FQDN ของ Azure Database for PostgreSQL>",
                    "-e", "PGUSER=<ชื่อผู้ใช้>",
                    "-e", "PGPASSWORD=<รหัสผ่าน>",
                    "-e", "PGDATABASE=<ชื่อฐานข้อมูล>",
                    "azure-postgresql-mcp:local"
                ]
            }
        }
    }
    ```

    บน Windows ถ้า `docker` ไม่อยู่ใน PATH ที่ Claude Desktop เห็น ให้ใส่ path เต็มของ `docker.exe` ใน `"command"` (มักอยู่ใต้โฟลเดอร์ติดตั้ง Docker Desktop)

3. รีสตาร์ท Claude Desktop

**Microsoft Entra (Docker):** ส่งตัวแปรชุดเดียวกับ [วิธีการยืนยันตัวตนด้วย Microsoft Entra](#using-microsoft-entra-th) โดยเพิ่ม `-e` (เช่น `AZURE_USE_AAD`, `AZURE_SUBSCRIPTION_ID`, `AZURE_RESOURCE_GROUP`) หากใช้ `az login` บน host สามารถ mount โฟลเดอร์ credential ของ Azure CLI เข้า container (path ต่างกันตาม OS; ตัวอย่าง Linux/macOS):

```text
-v ~/.azure:/root/.azure:ro
```

ใส่สตริงนี้ในอาร์เรย์ `"args"` หลัง `"run", "-i", "--rm",` และก่อน `-e` container รันเป็น root โฟลเดอร์ credential ภายใน container คือ `/root/.azure` ปรับถ้าใช้ user ที่ไม่ใช่ root ใน image ที่ปรับแต่งเอง

#### ใช้ MCP Server กับ Visual Studio Code (Docker)

1. สร้าง image (ดู [สร้าง image](#build-docker-image))
2. เปิด **Settings** ค้นหา **MCP** แล้วแก้ `settings.json` ตัวอย่าง:

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
                        "-e", "PGHOST=<ชื่อ FQDN ของ Azure Database for PostgreSQL>",
                        "-e", "PGUSER=<ชื่อผู้ใช้>",
                        "-e", "PGPASSWORD=<รหัสผ่าน>",
                        "-e", "PGDATABASE=<ชื่อฐานข้อมูล>",
                        "azure-postgresql-mcp:local"
                    ]
                }
            }
        }
    }
    ```

3. ใช้ Copilot Chat ในโหมด Agent แล้วเลือกเครื่องมือ MCP ตามที่อธิบายในส่วน VS Code ด้านล่าง

#### ทางเลือก: ทดสอบด้วยมือ

เพื่อยืนยันว่า image เริ่มทำงานได้ (โปรเซสจะรอ MCP บน stdio):

```bash
docker run -i --rm -e PGHOST=example.postgres.database.azure.com -e PGUSER=user -e PGPASSWORD=pass azure-postgresql-mcp:local
```

หยุดด้วย Ctrl+C การทดสอบนี้ไม่ได้พิสูจน์การเชื่อมต่อฐานข้อมูลจริง ยกเว้นค่าตัวแปรชี้ไปยังเซิร์ฟเวอร์จริง

### ใช้ MCP Server กับ Claude Desktop

ดูวิดีโอสาธิต หรือทำตามขั้นตอนด้านล่าง

https://github.com/user-attachments/assets/d45da132-46f0-48ac-a1b9-3b1b1b8fd638

1. ใน Claude Desktop ไปที่แท็บ **Settings** เลือก **Developer** แล้วคลิก **Edit Config**
2. เปิดไฟล์ `claude_desktop_config.json` แล้วเพิ่มการตั้งค่าต่อไปนี้ในส่วน `mcpServers`:

    ```json
    {
        "mcpServers": {
            "azure-postgresql-mcp": {
                "command": "<path ไปยัง virtual environment>\\azure-postgresql-mcp-venv\\Scripts\\python",
                "args": [
                    "<path ไปยังไฟล์ azure_postgresql_mcp.py>\\azure_postgresql_mcp.py"
                ],
                "env": {
                    "PGHOST": "<ชื่อ FQDN ของ Azure Database for PostgreSQL>",
                    "PGUSER": "<ชื่อผู้ใช้>",
                    "PGPASSWORD": "<รหัสผ่าน>",
                    "PGDATABASE": "<ชื่อฐานข้อมูล>"
                }
            }
        }
    }
    ```

    **หมายเหตุ:** ตัวอย่างนี้ใช้การยืนยันตัวตนด้วยรหัสผ่านเพื่อทดสอบเท่านั้น แนะนำให้ใช้ Microsoft Entra ดู [คำแนะนำด้านล่าง](#using-microsoft-entra-th)
3. รีสตาร์ท Claude Desktop
4. หลังรีสตาร์ทจะเห็นไอคอนค้อนด้านล่างช่องพิมพ์ คลิกเพื่อดูเครื่องมือจาก MCP Server

พร้อมใช้งานกับข้อมูลผ่าน Claude Desktop ด้วยภาษาธรรมชาติ

### ใช้ MCP Server กับ Visual Studio Code

ดูวิดีโอสาธิต หรือทำตามขั้นตอนด้านล่าง

https://github.com/user-attachments/assets/12328e84-7045-4e3c-beab-4936d7a20c21

1. ใน Visual Studio Code เลือก **File → Preferences → Settings**
2. ค้นหา **MCP** แล้วเลือก **Edit in settings.json**
3. เพิ่มการตั้งค่าต่อไปนี้ในส่วน `mcp` ของ `settings.json`:

    ```json
    {
        "mcp": {
            "inputs": [],
            "servers": {
                "azure-postgresql-mcp": {
                    "command": "<path ไปยัง virtual environment>\\azure-postgresql-mcp-venv\\Scripts\\python",
                    "args": [
                        "<path ไปยังไฟล์ azure_postgresql_mcp.py>\\azure_postgresql_mcp.py"
                    ],
                    "env": {
                        "PGHOST": "<ชื่อ FQDN ของ Azure Database for PostgreSQL>",
                        "PGUSER": "<ชื่อผู้ใช้>",
                        "PGPASSWORD": "<รหัสผ่าน>",
                        "PGDATABASE": "<ชื่อฐานข้อมูล>"
                    }
                }
            }
        }
    }
    ```

    **หมายเหตุ:** ตัวอย่างนี้ใช้การยืนยันตัวตนด้วยรหัสผ่านเพื่อทดสอบเท่านั้น แนะนำให้ใช้ Microsoft Entra ดู [คำแนะนำด้านล่าง](#using-microsoft-entra-th)
4. คลิกไอคอนสถานะ **Copilot** มุมขวาบนเพื่อเปิด GitHub Copilot Chat
5. เลือก **Agent mode** จากเมนูด้านล่างช่องแชท
6. คลิก **Select Tools** (ไอคอนค้อน) เพื่อดูเครื่องมือจาก MCP Server

พร้อมใช้งานกับข้อมูลผ่าน VS Code ด้วยภาษาธรรมชาติ

<a id="using-microsoft-entra-th"></a>
## วิธีการยืนยันตัวตนด้วย Microsoft Entra

เพื่อใช้ Microsoft Entra (แนะนำ) ในการเชื่อม MCP Server กับ Azure Database for PostgreSQL ให้อัปเดตการตั้งค่าใน `claude_desktop_config.json` (Claude Desktop) และ `settings.json` (Visual Studio Code) ดังนี้:

```json
"azure-postgresql-mcp": {
    "command": "<path ไปยัง virtual environment>\\azure-postgresql-mcp-venv\\Scripts\\python",
    "args": [
        "<path ไปยังไฟล์ azure_postgresql_mcp.py>\\azure_postgresql_mcp.py"
    ],
    "env": {
        "PGHOST": "<ชื่อ FQDN ของ Azure Database for PostgreSQL>",
        "PGUSER": "<ชื่อผู้ใช้ Microsoft Entra ID หรือชื่อทรัพยากรที่มี system-assigned identity หรือชื่อ identity>",
        "AZURE_USE_AAD": "True",
        "AZURE_SUBSCRIPTION_ID": "<Azure subscription ID>",
        "AZURE_RESOURCE_GROUP": "<Resource Group ที่มีอินสแตนซ์ Azure Database for PostgreSQL>"
    }
}
```

## การตรวจสอบว่ารันและใช้งานสำเร็จ

ทำตามลำดับด้านล่างเพื่อยืนยันว่าเซิร์ฟเวอร์ การเชื่อมฐานข้อมูล และการเชื่อม MCP ทำงานครบ

### 1. Unit tests (ไม่ต้องมีฐานข้อมูล Azure)

หลังติดตั้ง dependencies และ `pytest`:

```bash
pip install pytest
PYTHONPATH=src pytest --color=yes -v
```

เทสต์ควรผ่านทั้งหมด ขั้นตอนนี้ตรวจโค้ด Python ด้วย mock **ไม่ได้**เชื่อมต่อ Azure จริง ดูรายละเอียดใน [tests/README.md](tests/README.md)

### 2. การเชื่อมต่อฐานข้อมูล (ยืนยันตัวตนด้วยรหัสผ่าน)

ยืนยันว่าเครื่องของคุณ (หรือ host ที่รัน Docker) เข้าถึงเซิร์ฟเวอร์ได้และ credential ถูกต้อง Azure Database for PostgreSQL มักบังคับใช้ TLS ตัวอย่างด้วย [psql](https://www.postgresql.org/docs/current/app-psql.html):

```bash
export PGHOST="<your-server>.postgres.database.azure.com"
export PGUSER="<user>"
export PGPASSWORD="<password>"
psql "host=$PGHOST port=5432 dbname=postgres user=$PGUSER password=$PGPASSWORD sslmode=require" -c "SELECT 1"
```

ถ้าสำเร็จจะได้แถวผลลัพธ์เป็น `1` ถ้าไม่ผ่านให้แก้ไฟร์วอลล์ เครือข่าย หรือ credential ก่อนไล่แก้ MCP

### 3. MCP Inspector (ทดสอบ MCP แบบ end-to-end กับฐานข้อมูลจริง)

[MCP Inspector](https://modelcontextprotocol.io/docs/tools/inspector) ใช้ทดสอบโปรโตคอล MCP และเรียกเครื่องมือจากเบราว์เซอร์ ต้องติดตั้ง [Node.js](https://nodejs.org/) เวอร์ชัน ^22.7.5 ขึ้นไป (ตรวจด้วย `node -v`)

**รันด้วย Python บนเครื่อง** (โฟลเดอร์รากของ repo เปิด venv และติดตั้ง dependencies แล้ว):

```bash
npx -y @modelcontextprotocol/inspector \
  -e PGHOST="<your-server>.postgres.database.azure.com" \
  -e PGUSER="<user>" \
  -e PGPASSWORD="<password>" \
  python src/azure_postgresql_mcp.py
```

**รันด้วย Docker** (หลัง [สร้าง image](#build-docker-image)):

```bash
npx -y @modelcontextprotocol/inspector \
  docker run -i --rm \
  -e PGHOST="<your-server>.postgres.database.azure.com" \
  -e PGUSER="<user>" \
  -e PGPASSWORD="<password>" \
  azure-postgresql-mcp:local
```

เปิด URL ที่เทอร์มินัลแสดง (มักเป็น `http://localhost:6274`) ใน UI เชื่อมต่อเซิร์ฟเวอร์ เปิดแท็บ **Tools** แล้วลองรัน **`get_databases`** (หรือเครื่องมืออื่น) ถ้าได้ผลลัพธ์ถูกต้อง แปลว่าโปรเซส MCP โปรโตคอล และการเชื่อม PostgreSQL ใช้งานร่วมกันได้

สำหรับ Microsoft Entra ให้ส่งตัวแปรสภาพแวดล้อมชุดเดียวกับ [วิธีการยืนยันตัวตนด้วย Microsoft Entra](#using-microsoft-entra-th) ผ่าน `-e` เพิ่มเติม และให้ `DefaultAzureCredential` ดึง credential บนเครื่องนั้นได้ (ถ้าใช้ Docker ดูหมายเหตุเรื่อง mount `~/.azure` เมื่อใช้ `az login`)

### 4. MCP client ที่คุณใช้ (Claude Desktop / VS Code)

หลังตั้งค่า client แล้ว:

- **Claude Desktop:** มีไอคอนค้อนใกล้ช่องแชท เปิดเพื่อดูรายการเครื่องมือ (เช่น `get_databases`)
- **VS Code:** ใน GitHub Copilot Chat โหมด **Agent** ใช้ **Select Tools** (ค้อน) แล้วตรวจว่ามีเครื่องมือชุดเดียวกัน

ลองเรียกเครื่องมือง่ายๆ จาก client ถ้า Inspector ใช้ได้แต่ client ไม่ได้ ให้ตรวจ path ของ executable ตัวแปรสภาพแวดล้อม และว่าแอปเห็น `docker` หรือ `python` ใน `PATH` หรือไม่

## การมีส่วนร่วม

Azure Database for PostgreSQL MCP Server อยู่ในช่วงพรีวิว เรายินดีรับการมีส่วนร่วมทุกรูปแบบ รายละเอียดเพิ่มเติมอยู่ใน [CONTRIBUTING.md](CONTRIBUTING.md)

## สัญญาอนุญาต

โปรเจกต์นี้อยู่ภายใต้ MIT License ดูรายละเอียดใน [LICENSE](LICENSE.md)
