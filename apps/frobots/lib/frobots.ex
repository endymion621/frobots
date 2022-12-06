defmodule Frobots do
  @moduledoc """
  Frobots keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  @app :frobots
  @priv_dir "#{:code.priv_dir(@app)}"
  @home_dir "#{System.user_home!()}"
  @bots_dir "bots"
  @template_dir "templates"

  alias Frobots.ApiClient
  alias Frobots.MatchChannelAdapter

  @prototype_class "Proto"
  @target_class "Target"
  @user_class_u "U"

  def user_classes() do
    [@user_class_u]
  end

  def prototype_class() do
    @prototype_class
  end

  def target_class() do
    @target_class
  end

  @doc """
    @frobot_types [
      {"Rabbit", :rabbit},
      {"Sniper", :sniper},
      {"Random", :random},
      {"Rook", :rook},
      {"Tracker", :tracker},
      {"Target", :target},
      {"Dummy", :dummy}
    ]


  """
  def user_frobot_path() do
    Path.join([@home_dir, @bots_dir])
  end

  def template_frobot_path() do
    Path.join([@priv_dir, @template_dir])
  end

  def frobot_names(frobot_list) do
    Enum.map(frobot_list, fn f -> f["name"] end)
  end

  def frobot_types() do
    frobot_list = frobot_names(ApiClient.get_user_frobots() ++ ApiClient.get_template_frobots())
    Enum.map(frobot_list, fn x -> {x, String.to_atom(x)} end)
  end

  def user_frobot_types() do
    frobot_list = frobot_names(ApiClient.get_user_frobots())
    Enum.map(frobot_list, fn x -> {x, String.to_atom(x)} end)
  end

  def proto_frobot_types() do
    frobot_list = frobot_names(ApiClient.get_template_frobots())
    Enum.map(frobot_list, fn x -> {x, String.to_atom(x)} end)
  end

  def start_fubars(match_data) do
    # return a frobots_map {name:frobot object_data}, but setup the channel adapter
    MatchChannelAdapter.start_match(MatchChannelAdapter, match_data)
  end

  def request_match() do
    MatchChannelAdapter.request_match(MatchChannelAdapter)
  end

  def cancel_match(), do: MatchChannelAdapter.cancel_match(MatchChannelAdapter)

  # this loads the frobots from server and saves them to the directory
  def load_player_frobots() do
    frobots =
      ApiClient.get_user_frobots()
      |> Enum.filter(fn f -> f["class"] == "U" end)

    Enum.each(frobots, fn f ->
      ConCache.put(:frobots, f["name"], f["id"])
      File.mkdir_p!(user_frobot_path())
      File.write(~s|#{user_frobot_path()}/#{f["name"]}.lua|, f["brain_code"])
    end)

    templates = ApiClient.get_template_frobots()

    IO.inspect(
      Enum.each(templates, fn f ->
        ConCache.put(:frobots, f["name"], f["id"])
        File.mkdir_p!(template_frobot_path())
        File.write(~s|#{template_frobot_path()}/#{f["name"]}.lua|, f["brain_code"])
      end)
    )
  end

  # the following with read all the frobots in the local directory and upload them to the server.
  def save_player_frobots() do
    # first load all the frobots, so that we don't create duplicates
    frobots = ApiClient.get_user_frobots()

    Enum.each(frobots, fn f ->
      ConCache.put(:frobots, f["name"], f["id"])
    end)

    ApiClient.upload_user_frobots()
  end
end
