version: '3.8'

services:
  postgres:
    image: postgres:15
    restart: unless-stopped
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./initdb:/docker-entrypoint-initdb.d
    environment:
      - POSTGRES_PASSWORD=${postgres_password}
      - POSTGRES_USER=${postgres_user}
      - POSTGRES_DB=${postgres_db}
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${postgres_user}"]
      interval: 10s
      timeout: 5s
      retries: 5

  postgrest:
    image: postgrest/postgrest:v13.0.0
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      - PGRST_DB_URI=postgres://${postgres_user}:${postgres_password}@postgres:5432/${postgres_db}
      - PGRST_DB_SCHEMA=public
      - PGRST_DB_ANON_ROLE=${postgres_user}
      - PGRST_SERVER_PORT=3000
    ports:
      - "3000:3000"

  pgeonui:
    image: ${app_docker_image}
    restart: unless-stopped
    depends_on:
      - postgrest
    ports:
      - "80:8082"
    environment:
      - POSTGRES_USER=${postgres_user}
      - POSTGRES_PASSWORD=${postgres_password}
      - POSTGRES_DB=${postgres_db}
      - POSTGRES_HOST=postgres
      - POSTGRES_PORT=5432
      - POSTGREST_URL=http://postgrest:3000

  watchtower:
    image: containrrr/watchtower
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    command: --interval 30 --cleanup pgeonui
    environment:
      - WATCHTOWER_CLEANUP=true
      - WATCHTOWER_INCLUDE_STOPPED=true

volumes:
  postgres-data:

networks:
  default:
    name: pgeonui-network
