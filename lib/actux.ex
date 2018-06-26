defmodule Actux do
  @moduledoc """
    This module contains the GenEvent that you can use to transmit logs or
    analytics for your Elixir applications to actus.

    ### Configuring

    By default the ACTUS_HOST environment variable is used to set the location
    of the timescaledb. You can manually set your host, and other defaults, by
    configuring the :actux application.

        config :logger, :actux,
          actus_host: System.get_env("ACTUS_HOST"),
          namespace: "myNamespace",
          level: :info,
          table: "myTable"

    The configuration defaults to:

        config :logger, :actux,
          actus_host: "https://actus-bleeping.vidangel.com",
          namespace: "event",
          level: :info,
          metadata: [],
          timeout: 5000,
          table: :application.get_application
  """

  import Logger.Formatter, only: [format_date: 1, format_time: 1]

  @default_actus_host "https://actus-bleeping.vidangel.com"

  @doc false
  def init({__MODULE__, name}) do
    {:ok, setup(name, [])}
  end

  @doc false
  def handle_call({:setup, opts}, %{name: name}) do
    {:ok, :ok, setup(name, opts)}
  end

  @doc false
  def handle_event({_level, gl, _event}, config) when node(gl) != node() do
    {:ok, config}
  end

  @doc false
  def handle_event({level, _gl, {Logger, msg, timestamp, metadata}}, config) do
    if meet_level?(level, config.level) do
      log_event(level, msg, timestamp, metadata, config)
    end
    {:ok, config}
  end

  defp meet_level?(_lvl, nil), do: true
  defp meet_level?(lvl, min) do
   Logger.compare_levels(lvl, min) != :lt
  end

  defp get_config(environment, key, default) do
    Keyword.get(environment, key, default)
  end

  def format_event(level, msg, timestamp, metadata) do
    %{
      level: level,
      time: event_time(timestamp),
      msg: (msg |> IO.iodata_to_binary)
    }
    |> Map.merge(Enum.into(metadata, %{}))
    |> Poison.encode!
    |> Kernel.<>("\n")
  end

  defp event_time({date, time}) do
    [format_date(date), format_time(time)]
    |> Enum.join(" ")
  end

  defp log_event(level, msg, timestamp, metadata, config) do
    output = format_event(level, msg, timestamp, metadata)
    headers = [{"Content-type", "application/json"}]
    case HTTPoison.post(config.url, output, headers, timeout: config.timeout) do
      {:ok, %HTTPoison.Response{status_code: status}} ->
        {:ok, status}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  defp setup(name, opts) do
    environment = Application.get_env(:logger, name, [])
    opts = Keyword.merge(environment, opts)
    Application.put_env(:logger, name, opts)

    level = get_config(opts, :level, :info)
    table = get_config(opts, :table, :application.get_application)
    timeout = get_config(opts, :timeout, 5000)
    namespace = get_config(opts, :namespace, "event")
    host = get_config(opts, :actus_host, @default_actus_host)
    metadata = get_config(opts, :metadata, [])

    %{name: name,
      url: "#{host}/#{namespace}/#{table}",
      level: level,
      metadata: metadata,
      timeout: timeout}
  end
end
