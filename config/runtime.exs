import Config

config :frobots, bearer_token: System.get_env("CLIENT_TOKEN")

config :frobots_scenic, :image_path, %{
  blue1: :code.priv_dir(:frobots_scenic) |> Path.join("/static/images/blue1.png"),
  blue2: :code.priv_dir(:frobots_scenic) |> Path.join("/static/images/blue2.png"),
  blue3: :code.priv_dir(:frobots_scenic) |> Path.join("/static/images/blue3.png"),
  blue4: :code.priv_dir(:frobots_scenic) |> Path.join("/static/images/blue4.png"),
  blue5: :code.priv_dir(:frobots_scenic) |> Path.join("/static/images/blue5.png"),
  blue6: :code.priv_dir(:frobots_scenic) |> Path.join("/static/images/blue6.png"),
  blue7: :code.priv_dir(:frobots_scenic) |> Path.join("/static/images/blue7.png"),
  blue8: :code.priv_dir(:frobots_scenic) |> Path.join("/static/images/blue8.png"),
  blue9: :code.priv_dir(:frobots_scenic) |> Path.join("/static/images/blue9.png"),
  red1: :code.priv_dir(:frobots_scenic) |> Path.join("/static/images/red1.png"),
  red2: :code.priv_dir(:frobots_scenic) |> Path.join("/static/images/red2.png"),
  red3: :code.priv_dir(:frobots_scenic) |> Path.join("/static/images/red3.png"),
  red4: :code.priv_dir(:frobots_scenic) |> Path.join("/static/images/red4.png"),
  red5: :code.priv_dir(:frobots_scenic) |> Path.join("/static/images/red5.png"),
  red6: :code.priv_dir(:frobots_scenic) |> Path.join("/static/images/red6.png"),
  red7: :code.priv_dir(:frobots_scenic) |> Path.join("/static/images/red7.png"),
  yellow1: :code.priv_dir(:frobots_scenic) |> Path.join("/static/images/yellow1.png"),
  yellow2: :code.priv_dir(:frobots_scenic) |> Path.join("/static/images/yellow2.png"),
  rabbit: :code.priv_dir(:frobots_scenic) |> Path.join("/static/images/rabbit.png")
}

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.
if config_env() == :prod do
end
