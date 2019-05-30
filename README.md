# Actux

Actux is a collection of logging modules to push data to Actus from your elixir
app. It currently includes two modules:

  * ActusLogger -- a simple, standalone logger to push arbitrary data packets
  to a table and namespace of your choosing.
  * ActusBackend -- an integrated backend for elixir's built-in `:logger` module.
  * Actux.Plug -- A plug that normalizes and reports request data.

Other modules will be added soon, including `Plug`s for Ecto.

# Installation

To install, clone the repo and add `actux` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:actux, path: "/path/to/actux"}
  ]
end
```

You can also reference Actux as a git dependency (see [https://hexdocs.pm/mix/Mix.Tasks.Deps.html] for more details)

Actux must be loaded in `mix.exs` before your app, like this:

```elixir
def application do
  [
    applications: [:actux, :httpoison, :poison]
  ]
```

# Configuration

## Simple Logger
To configure actux, you can set the `actus_host` and
`actus_namespace` variables as part of your app's configuration file (under the
  `:actux` atom):

```elixir
config :actux,
  actus_host: System.get_env("ACTUS_HOST"),
  actus_namespace: "my_namespace"
```

## Logger Backend | Plug
### Basic Configuration
To configure the `:logger` backend instead, set ActusBackend to be the backend
for `:logger` and then add the Actux specific parameters:

```elixir
config :actux,
  actus_host: System.get_env("ACTUS_HOST"),
  actus_namespace: :default_namespace
  
config :logger,
  backends: [{ActuxBackend, :actux}]

config :logger, :actux,
  level: :info,
  actus_host: System.get_env("ACTUS_HOST"),
  actus_namespace: :logger_namespace,
  table: :logger_table
```

### Multiple Backends
You can log to multiple backends (e.g., Actus and the console) by
configuring all backends in the `config.exs` file. For example:

```elixir
config :logger,
  backends: [{ActuxBackend, :actux}, :console]
```

This can be especially useful if you want to incorporate debug logging that is
not sent to Actus; just configure Actux to be at one level (such as `info`), and
the console logger to be at a higher level:

```elixir
config :logger,
  backends: [{ActuxBackend, :actux}]

config :logger, :actux,
  level: :info

config :logger, :console,
  level: :debug
```

In this setup, all `Logger.debug` messages will only be output to the console,
while `Logger.info` messages will be sent to Actus and the console.

Note that when used as a full-fledged backend for `:logger`, you can configure
anything in Actux that you can in other backends, such as `format` and a
`truncate` bytes threshold. You can also set default metadata in the config
(such as a_id, i_id, etc.) that will be added to by any metadata you pass on
each `Logger` invocation.

### Limiting Scope
Besides configuring which `level` is used by Actux, if you need logging to Actus
limited to a specific log type, you can configure a list of allowed modules (I
don't know if this use case is super relevant, but at least for me I needed a
way to use the Actux.Plug without having to change the level of all other
logging)
 ```elixir
config :logger, :actux,
       allowed_modules: [Actux.Plug]
```

# Use

## Simple Logger
Require `ActusLogger` in the module where you'll be using it and,
whenever you need to send something to Actus, invoke the logger as its own
function call, passing it a table name and a map of the fields and values you
want to push:

```elixir
require ActusLogger

ActusLogger.push("myTable", %{"foo" => "bar"})
```

> Note:
> This doesn't utilize the logger's gen_event structure, and therefore requires
manual setup if you want it to run asynchronously

## Logger Backend
Require the `Logger` module and log as you would normally:

```elixir
require Logger

Logger.info "log message"
```

The Actux backend will send to your configured table a packet that includes
the log level, the time of the event, and the log message you specify. To send
additional fields and values, utilize the `metadata` argument (which takes a
keyword list):

```elixir
Logger.info "log message", [foo: "bar", bat: "baz"]
```

## Plug
Add the `Actux.Plug` to your phoenix endpoint after static asset serving, but
before any other plugs (where the default `Plug.Logger` would be):

```elixir
  plug Actux.Plug,
       namespace: :plug_specific_namespace,
       table: :plug_specific_table
```
Namespace and table options here override both the `:actux` and the
`:logger, :actux` configurations.

The Actux Plug does use the Actux Backend in order to take advantage of the
asynchronous offloading.  Most of the plug's functionality is currently just
pulling data off of the `Plug.Conn` structure, parsing, and  formatting it to
match the other telemetry tables currently set up in Actus.
