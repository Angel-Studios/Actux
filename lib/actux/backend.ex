defmodule Actux.Backend do
  @moduledoc """
    This module contains the GenEvent that you can use to transmit logs or
    analytics for your Elixir applications to actus.

    ## Configuring

    The location of the timescaledb is configured in the application's `Actux`
    configuration. All other defaults for the backend can be specified by
    configuring the :logger :actux backend.

    ```elixir
      config :logger, :actux,
        namespace: :my_namespace,
        level: :info,
        table: :my_table
    ```

    The configuration defaults to:
    - namespace: `nil` (fallback to application actux configuration)
    - level: `:info`
    - metadata: `[]`
    - table: `:info`
  """
  @behaviour :gen_event

  import Logger.Formatter, only: [format_date: 1, format_time: 1]

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
    case meet_level?(level, config.level) && allow_module?(metadata, config.allowed_modules) do
      true -> log_event(level, msg, timestamp, metadata, config)
      false -> {:ok, config}
    end
  end

  defp allow_module?(_metadata, []), do: true
  defp allow_module?(metadata, allowed_modules), do: Keyword.get(metadata, :module) in allowed_modules

  defp meet_level?(_lvl, nil), do: true
  defp meet_level?(lvl, min) do
   Logger.compare_levels(lvl, min) != :lt
  end

  defp get_config(environment, key, default) do
    Keyword.get(environment, key, default)
  end

  def format_event(level, msg, timestamp, metadata) do
    excluded_keys = [:pid, :module, :function, :file, :line, :crash_reason]
    %{
      level: level,
      time: event_time(timestamp),
      msg: (msg |> IO.iodata_to_binary)
    }
    |> Map.merge(Map.drop(Enum.into(metadata, %{}), excluded_keys))
  end

  defp event_time({date, time}) do
    [format_date(date), format_time(time)]
    |> Enum.join(" ")
  end

  defp log_event(level, msg, timestamp, metadata, config) do
    output = case Keyword.get(metadata, :request_attrs) do
      nil -> format_event(level, msg, timestamp, metadata)
      attrs -> Actux.Request.from_attrs(attrs)
    end
    Actux.push(namespace(metadata, config), table(metadata, config), output)
    {:ok, config}
  end

  defp table(metadata, config) do
    Keyword.get(metadata, :table, config.table)
  end

  defp namespace(metadata, config) do
    Keyword.get(metadata, :namespace, config.namespace)
  end

  defp setup(name, opts) do
    environment = Application.get_env(:logger, name, [])
    opts = Keyword.merge(environment, opts)
    Application.put_env(:logger, name, opts)

    format = Keyword.get(opts, :format) |> Logger.Formatter.compile
    formatter = get_config(opts, :formatter, Logger.Formatter)
    level = get_config(opts, :level, :info)
    table = get_config(opts, :table, :info)
    namespace = get_config(opts, :actus_namespace, :event)
    metadata = get_config(opts, :metadata, [])

    %{
      format: format,
      formatter: formatter,
      level: level,
      metadata: metadata,
      name: name,
      namespace: namespace,
      allowed_modules: get_config(opts, :allowed_modules, []),
      table: table,
    }
  end
end
