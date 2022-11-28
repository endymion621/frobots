import Config

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

config :phoenix_client,
  socket: [
    url: "wss://dev-internal.frobots.io/socket/websocket"
  ],
  api: [
    url: "https://dev-internal.frobots.io/api/v1"
  ],
  token: [
    url: "https://dev-internal.frobots.io/token"
  ]
