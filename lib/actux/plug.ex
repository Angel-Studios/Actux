defmodule Actux.Plug do
  @moduledoc """
  A plug for logging request information
  ## Options
    * `:namespace` - The actus namespace, overrides application configuration.
    * `:table` - The table to log to. Default is `"requests"`.
  """

  require Logger
  alias Plug.Conn

  @behaviour Plug

  def init(opts) do
    Keyword.merge([table: :requests], opts)
  end

  def call(conn, opts) do
    request_start = System.monotonic_time()

    Conn.register_before_send(
      conn,
      fn conn ->
        response_time = response_time(request_start)
        Logger.info "Sending Request data to Actus",
                    namespace: Keyword.get(opts, :namespace),
                    table: Keyword.get(opts, :table),
                    request_attrs: %{
                      url: Conn.request_url(conn),
                      user_agent: user_agent_string(conn),
                      status_code: conn.status,
                      response_time: response_time,
                      user: conn.assigns[:user],
                      remote_ip: conn.remote_ip
                    }
        conn
      end
    )
  end

  defp response_time(start_time) do
    System.monotonic_time()
    |> Kernel.-(start_time)
    |> System.convert_time_unit(:native, :microsecond)
  end

  defp user_agent_string(conn) do
    conn
    |> Conn.get_req_header("user-agent")
    |> List.first()
  end

end