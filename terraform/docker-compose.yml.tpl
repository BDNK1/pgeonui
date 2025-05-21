version: '3.8'

services:
  postgres:
    image: postgres:15
    depends_on:
      - fluentd
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
    logging:
      driver: "fluentd"
      options:
        fluentd-address: localhost:24224
        tag: docker.postgres.${instance_name}

  postgrest:
    image: postgrest/postgrest:v13.0.0
    restart: unless-stopped
    depends_on:
      fluentd:
        condition: service_started
      postgres:
        condition: service_healthy
    environment:
      - PGRST_DB_URI=postgres://${postgres_user}:${postgres_password}@postgres:5432/${postgres_db}
      - PGRST_DB_SCHEMA=public
      - PGRST_DB_ANON_ROLE=${postgres_user}
      - PGRST_SERVER_PORT=3000
    ports:
      - "3000:3000"
    logging:
      driver: "fluentd"
      options:
        fluentd-address: localhost:24224
        tag: docker.postgrest.${instance_name}

  pgeonui:
    image: ${app_docker_image}
    restart: unless-stopped
    depends_on:
      - postgrest
      - fluentd
    ports:
      - "80:8082"
    environment:
      - POSTGRES_USER=${postgres_user}
      - POSTGRES_PASSWORD=${postgres_password}
      - POSTGRES_DB=${postgres_db}
      - POSTGRES_HOST=postgres
      - POSTGRES_PORT=5432
      - POSTGREST_URL=http://postgrest:3000
    logging:
      driver: "fluentd"
      options:
        fluentd-address: localhost:24224
        tag: docker.pgeonui.${instance_name}

  watchtower:
    image: containrrr/watchtower
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    command: --interval 60 --cleanup pgeonui
    environment:
      - WATCHTOWER_CLEANUP=true
      - WATCHTOWER_INCLUDE_STOPPED=true

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:9.0.1
    restart: unless-stopped
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false # For dev; enable security for production
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    volumes:
      - elasticsearch-data:/usr/share/elasticsearch/data
    ports:
      - "9200:9200"
    networks:
      - default
    healthcheck:
      test: ["CMD-SHELL", "curl -s --fail http://localhost:9200/_cluster/health?wait_for_status=yellow&timeout=5s || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5

  kibana:
    image: docker.elastic.co/kibana/kibana:9.0.1
    restart: unless-stopped
    ports:
      - "5601:5601" # Expose Kibana
    environment:
      ELASTICSEARCH_HOSTS: http://elasticsearch:9200
    depends_on:
      elasticsearch:
        condition: service_healthy
    networks:
      - default

  fluentd:
    build:
      context: ./fluentd
    restart: unless-stopped
    volumes:
      - ./fluentd:/fluentd/etc
      - /var/run/docker.sock:/var/run/docker.sock
    ports:
      - "24224:24224"
      - "24224:24224/udp"
    depends_on:
      elasticsearch:
        condition: service_healthy
    networks:
      - default

volumes:
  postgres-data:
  elasticsearch-data:

networks:
  default:
    name: pgeonui-network
