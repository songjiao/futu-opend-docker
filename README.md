# Futu OpenD Docker

Dockerized [Futu OpenD](https://openapi.futunn.com/futu-api-doc/opend/opend-cmd.html) (trading API gateway) with secure runtime configuration.

Credentials are never baked into the Docker image — the XML config is generated at container startup from environment variables.

## Prerequisites

- Docker & docker-compose
- A [Futu/Moomoo](https://www.futunn.com/) account
- (Optional) RSA private key for API encryption (PKCS#1 format)

## Quick Start

```bash
# 1. Clone
git clone git@github.com:songjiao/futu-opend-docker.git
cd futu-opend-docker

# 2. Configure credentials
cp .env.example .env
# Edit .env — fill in FUTU_LOGIN_ACCOUNT and FUTU_LOGIN_PWD_MD5

# 3. Create directories
mkdir -p data secrets

# 4. Generate RSA key pair for API encryption
./gen-rsa-key.sh
# Then uncomment FUTU_RSA_KEY_PATH in .env

# 5. Build and start
docker-compose up -d --build
```

## First-Time Setup

On first login, OpenD requires **SMS verification**. The verification is done through OpenD's interactive console:

```bash
# Attach to the container console
docker attach futu-opend

# You will see: "Need a phone verification code"
# Request the code (if not auto-sent):
req_phone_verify_code

# Enter the code received via SMS:
input_phone_verify_code -code=123456

# Detach without stopping the container:
# Press Ctrl+P, then Ctrl+Q
```

> **Note:** After verification, device trust is persisted in `./data/`. Subsequent restarts will not require re-verification.

### Regulatory Questionnaire

After first login, OpenD may exit with a message like:

```
In order to meet regulatory requirements, API users need to conduct
relevant questionnaire evaluation and agreement confirmation...
```

Open the URL shown in `docker logs futu-opend` in your browser, complete the questionnaire, and the container will auto-restart and run normally.

## Generate RSA Key

Required for API encryption when listening on non-localhost (which is the case in Docker). The same private key is shared between OpenD and the API client SDK.

```bash
./gen-rsa-key.sh        # Default: 1024-bit PKCS#1
./gen-rsa-key.sh 512    # Or 512-bit
```

Key is saved to `./secrets/rsa_private.pem`. In your API client:
```python
SysConfig.enable_proto_encrypt(True)
SysConfig.set_init_rsa_file("rsa_private.pem")
```

## Generate MD5 Password

```bash
echo -n "your_password" | md5sum | awk '{print $1}'
```

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `FUTU_LOGIN_ACCOUNT` | Yes | — | Futu user ID, phone, or email |
| `FUTU_LOGIN_PWD_MD5` | Yes* | — | MD5 password (32-bit hex) |
| `FUTU_LOGIN_PWD` | Yes* | — | Plaintext password (not recommended) |
| `FUTU_API_PORT` | No | `11111` | API protocol listening port |
| `FUTU_LANG` | No | `en` | Language: `en` or `chs` |
| `FUTU_LOG_LEVEL` | No | `info` | Log level: `no`,`debug`,`info`,`warning`,`error`,`fatal` |
| `FUTU_PUSH_PROTO_TYPE` | No | `0` | Push protocol: `0` (protobuf), `1` (JSON) |
| `FUTU_TIMEZONE` | No | `UTC+8` | Futures trading API timezone |
| `FUTU_RSA_KEY_PATH` | No | — | RSA private key path inside container |
| `FUTU_WEBSOCKET_PORT` | No | — | WebSocket port (disabled if not set) |
| `FUTU_WEBSOCKET_KEY_MD5` | No | — | WebSocket authentication key (MD5) |
| `FUTU_PDT_PROTECTION` | No | — | Pattern Day Trade protection (US accounts) |

\* One of `FUTU_LOGIN_PWD_MD5` or `FUTU_LOGIN_PWD` is required.

## Volumes

| Host Path | Container Path | Purpose |
|-----------|---------------|---------|
| `./data` | `/data` | Persistent AppData.dat (device trust) |
| `./secrets` | `/secrets` (read-only) | RSA private key |

## Common Commands

```bash
# Start
docker-compose up -d

# View logs
docker logs -f futu-opend

# Interactive console (for verification or admin commands)
docker attach futu-opend

# Rebuild after updating
docker-compose up -d --build

# Stop
docker-compose down
```

## Security

- Credentials are injected via environment variables at runtime, never stored in image layers
- RSA private key is mounted read-only from `./secrets/`
- `.env` and `secrets/` are gitignored
- Telnet port is only accessible inside the container (127.0.0.1)
