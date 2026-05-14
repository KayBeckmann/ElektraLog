FROM dart:stable AS builder
WORKDIR /app
COPY pubspec.* ./
RUN dart pub get
COPY . .
RUN dart compile exe bin/main.dart -o bin/server

FROM debian:bookworm-slim
WORKDIR /app
COPY --from=builder /app/bin/server ./server
EXPOSE 8080
CMD ["./server"]
