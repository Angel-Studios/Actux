defmodule ActuxBackend do
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
          actus_host: "https://actus-bleeping.vidangel.com",
          namespace: "event",
          level: :info,
          metadata: [],
          timeout: 5000,
          table: :application.get_application
  """
  @behaviour :gen_event

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

  def handle_event(:flush, state), do: {:ok, state}
  def handle_event({_level, gl, _event}, state) when node(gl) != node(), do: {:ok, state}
  def handle_event({level, _gl, {Logger, msg, timestamp, metadata}}, config) do
    case meet_level?(level, config.level) do
      true -> log_event(level, msg, timestamp, metadata, config)
      false -> {:ok, config}
    end
  end

  defp meet_level?(_lvl, nil), do: true
  defp meet_level?(lvl, min) do
   Logger.compare_levels(lvl, min) != :lt
  end

  defp get_config(environment, key, default) do
    Keyword.get(environment, key, default)
  end

  def format_event(level, msg, timestamp, metadata) do
    excluded_keys = [:pid, :module, :function, :file, :line]
    %{
      level: level,
      time: event_time(timestamp),
      msg: (msg |> IO.iodata_to_binary)
    }
    |> Map.merge(Map.drop(Enum.into(metadata, %{}), excluded_keys))
    |> Poison.encode!
  end

  defp event_time({date, time}) do
    [format_date(date), format_time(time)]
    |> Enum.join(" ")
  end

  defp log_event(level, msg, timestamp, metadata, config) do
    output = format_event(level, msg, timestamp, metadata)
    headers = [{"Content-type", "application/json"}]
    IO.puts inspect(config.url)
    HTTPoison.post!(config.url, output, headers, timeout: config.timeout)
  end

  defp setup(name, opts) do
    environment = Application.get_env(:logger, name, [])
    opts = Keyword.merge(environment, opts)
    Application.put_env(:logger, name, opts)

    format = Keyword.get(opts, :format) |> Logger.Formatter.compile
    formatter = get_config(opts, :formatter, Logger.Formatter)
    level = get_config(opts, :level, :info)
    table = get_config(opts, :table, "mytable")
    timeout = get_config(opts, :timeout, 5000)
    namespace = get_config(opts, :namespace, "event")
    host = get_config(opts, :actus_host, @default_actus_host)
    metadata = get_config(opts, :metadata, [])

    %{name: name,
      format: format,
      formatter: formatter,
      url: "#{host}/#{namespace}/#{table}",
      level: level,
      metadata: metadata,
      timeout: timeout}
  end
end
