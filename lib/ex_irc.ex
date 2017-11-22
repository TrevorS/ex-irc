defmodule ExIRC do
  use GenServer

  alias ExIRC.Config

  def start_link(_) do
    port = Config.port()

    :ranch.start_listener(make_ref(), :ranch_tcp, [port: port], ExIRC.Protocol, [])
  end
end
