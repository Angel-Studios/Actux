defmodule Actux.Request do
  @moduledoc """
  Specific formatting for logging "requests" to actus.

  The logger formatting normally outputs a single line/string, but our actus
  calls take a json object; hence building out a struct to define that structure.
  """

  alias __MODULE__
  alias Plug.Conn
  @derive Jason.Encoder

  defstruct [
    :browser,
    :browser_name,
    :browser_version,
    :device,
    :device_family,
    :os_name,
    :os_version,
    :response_time,
    {:source, :server},
    :status_code,
    :url,
    :end_user,
  ]

  def from_conn(conn, response_time) do
    ua = user_agent(conn)
    %Request{
      source: :server,
      os_name: to_string(ua.os.family),
      os_version: to_string(ua.os.version),
      browser: to_string(ua),
      browser_name: to_string(ua.family),
      browser_version: to_string(ua.version),
      url: Conn.request_url(conn),
      device: to_string(ua.device),
      device_family: to_string(ua.device.brand),
      end_user: end_user(conn),
      status_code: conn.status,
      response_time: response_time,
    }
  end

  defp user_agent(conn) do
    conn
    |> Conn.get_req_header("user-agent")
    |> List.first()
    |> UAParser.parse()
  end

  defp end_user(%Conn{assigns: %{user: %{email: email}}}), do: email
  defp end_user(%Conn{remote_ip: address}),                do: address

end
