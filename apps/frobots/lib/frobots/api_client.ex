defmodule Frobots.ApiClient do
  use Tesla

  @user_frobot_path Frobots.user_frobot_path()

  # dynamic user & pass
  def login_client(username, password, opts \\ %{}) do
    Tesla.client([
      {Tesla.Middleware.BaseUrl,
       Keyword.fetch!(Application.get_env(:phoenix_client, :token), :url)},
      {Tesla.Middleware.BasicAuth, Map.merge(%{username: username, password: password}, opts)},
      # defaults to 5
      {Tesla.Middleware.FollowRedirects, max_redirects: 3},
      Tesla.Middleware.JSON
    ])
  end

  def get_token(client) do
    # pass `client` argument to `Tesla.get` function
    case Tesla.get(client, "/generate/") do
      {:ok, %Tesla.Env{status: 200, body: %{"data" => %{"token" => token}}}} -> {:ok, token}
      {:ok, %Tesla.Env{status: 401}} -> {:error, 401}
      {_, %Tesla.Env{status: error_code}} -> {:error, error_code}
    end
  end

  def token_client() do
    Tesla.client([
      {Tesla.Middleware.BaseUrl,
       Keyword.fetch!(Application.get_env(:phoenix_client, :api), :url)},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.BearerAuth, token: Application.get_env(:frobots, :bearer_token)}
    ])
  end

  def get_user_frobots() do
    # this gets only the users frobots
    case Tesla.get(token_client(), "/frobots") do
      {:ok, %Tesla.Env{body: %{"data" => frobot_list}}} ->
        Enum.map(frobot_list, fn frobot ->
          frobot
        end)

      {:error, error} ->
        [error]
    end
  end

  def get_template_frobots() do
    case Tesla.get(token_client(), "/frobots/templates") do
      {:ok, %Tesla.Env{body: %{"data" => frobot_list}}} ->
        Enum.map(frobot_list, fn frobot -> frobot end)

      {:error, error} ->
        [error]
    end
  end

  def create_or_update_frobot(filename) do
    path = "/frobots"
    {:ok, code} = File.read(@user_frobot_path <> "/" <> filename)
    [name, _ext] = String.split(filename, ".")

    case ConCache.get(:frobots, name) do
      nil ->
        request_body = %{frobot: %{brain_code: code, name: name, class: "U"}}
        IO.inspect(Tesla.post(token_client(), path, request_body))

      id ->
        update_path = path <> "/" <> Integer.to_string(id)
        request_body = %{frobot: %{brain_code: code}}
        IO.inspect(Tesla.put(token_client(), update_path, request_body))
    end
  end

  def upload_user_frobots() do
    with {:ok, files} <- File.ls(@user_frobot_path),
         list <- Enum.filter(files, fn x -> String.contains?(x, ".lua") end) do
      Enum.map(list, &create_or_update_frobot/1)
    end
  end

  def delete_frobot(id) do
    path = "/frobots" <> "/" <> Integer.to_string(id)
    Tesla.delete(token_client(), path)
  end
end
