defmodule ExIRC.Application do
  use Application

  def start(_type, _args) do
    children = [
      ExIRC,
      ExIRC.Client.Store,
      ExIRC.Nickname.Store,
      ExIRC.Channel.Store,
      ExIRC.Session.Supervisor
    ]

    opts = [strategy: :one_for_one, name: ExIRC.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
