defmodule ActusLogger do
  @moduledoc """
    This module contains a simple logger that you can use to transmit logs or
    analytics for your Elixir applications to actus.

    ### Configuring

    You can set your host and namespace by configuring the :actux application.

    config :actux,
      actus_host: System.get_env("ACTUS_HOST"),
      actus_namespace: "myNamespace"

    If you do not configure the application, then the defaults will be:

      actus_host: "https://actus-bleeping.vidangel.com",
      actus_namespace: "event"
  """
  def push(table, data) do
    host = Application.get_env(:actux, :actus_host, "https://actus-bleeping.vidangel.com")
    namespace = Application.get_env(:actux, :actus_namespace, "event")
    body = Poison.encode!(data)
    headers = [{"Content-type", "application/json"}]
    url = "#{host}/#{namespace}/#{table}"
    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: status}} ->
        {:ok, status}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
