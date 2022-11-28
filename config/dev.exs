import Config

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

config :phoenix_client,
  socket: [
    url: "ws://localhost:4000/socket/websocket"
  ],
  api: [
    url: "http://localhost:4000/api/v1"
  ],
  token: [
    url: "http://localhost:4000/token"
  ]
