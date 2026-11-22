FROM dart:stable AS builder
WORKDIR /app
COPY pubspec.* ./
RUN dart pub get
COPY . .
RUN dart compile exe bin/main.dart -o bin/server

FROM debian:bookworm-slim
# CA-Zertifikate für ausgehende TLS-Verbindungen (SMTP-Versand); ohne sie
# scheitert jeder Handshake mit „TLS-Verbindung fehlgeschlagen“.
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /app/bin/server ./server
# Migrationsläufer liest sie beim Start (siehe lib/src/migrations.dart)
COPY --from=builder /app/migrations ./migrations
EXPOSE 8080
CMD ["./server"]
