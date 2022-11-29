import Config

# Do not print debug messages in production
config :logger, level: :info

config :phoenix_client,
  socket: [
    url: "wss://internal.frobots.io/socket/websocket"
  ],
  api: [
    url: "https://internal.frobots.io/api/v1"
  ],
  token: [
    url: "https://internal.frobots.io/token"
  ]
