defmodule ExIRC.Application do
  use Application

  def start(_type, _args) do
    children = [
      ExIRC,
      ExIRC.Session.Supervisor
    ]

    opts = [strategy: :one_for_one, name: ExIRC.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
