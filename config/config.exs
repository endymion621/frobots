# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

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

config :frobots, display_process_name: :arena_gui

# Configure the main viewport for the Scenic application
config :frobots_scenic, :viewport, %{
  name: :main_viewport,
  size: {1000, 1000},
  default_scene: {FrobotsScenic.Scene.Landing, FrobotsScenic.Scene.Start},
  drivers: [
    %{
      module: Scenic.Driver.Glfw,
      name: :glfw,
      opts: [resizeable: false, title: "frobots_scenic"]
    }
  ]

}

config :frobots, env: config_env()

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
