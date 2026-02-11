# Futu OpenD Docker

Dockerized Futu OpenD (trading API gateway) with secure runtime configuration.

## Tech Stack
- Docker / docker-compose
- Ubuntu 22.04 base image
- Bash (entrypoint script)

## Project Structure
```
├── Dockerfile           # Build image with OpenD binary
├── docker-compose.yml   # Container orchestration
├── entrypoint.sh        # Generates FutuOpenD.xml from env vars at runtime
├── .env.example         # All available env vars (committed)
├── .env                 # Actual credentials (gitignored)
├── secrets/             # RSA keys mount point (gitignored)
├── data/                # Persistent AppData.dat (gitignored)
```

## Key Design Decisions
- Credentials are NEVER in the Docker image; XML config is generated at runtime from env vars
- AppData.dat (device trust) is symlinked to persistent volume `/data/`
- First-time login requires SMS verification via `docker attach` (OpenD does not open ports until login completes)
- Container runs with `stdin_open + tty` for interactive console access

## Usage
```bash
cp .env.example .env     # Fill in credentials
mkdir -p data secrets
docker-compose up -d --build

# First-time SMS verification:
docker attach futu-opend
# In console: input_phone_verify_code -code=XXXXXX
# Detach without stopping: Ctrl+P, Ctrl+Q
```
