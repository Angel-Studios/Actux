defmodule Actux.Request do
  @moduledoc """
  Specific formatting for logging "requests" to actus.

  The logger formatting normally outputs a single line/string, but our actus
  calls take a json object; hence building out a struct to define that structure.
  """

  alias __MODULE__
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

  def from_attrs(attrs) do
    ua = UAParser.parse(attrs.user_agent)
    %Request{
      source: :server,
      os_name: to_string(ua.os.family),
      os_version: to_string(ua.os.version),
      browser: to_string(ua),
      browser_name: to_string(ua.family),
      browser_version: to_string(ua.version),
      url: attrs.url,
      device: to_string(ua.device),
      device_family: to_string(ua.device.brand),
      end_user: attrs.end_user,
      status_code: attrs.status_code,
      response_time: attrs.response_time,
    }
  end

end
