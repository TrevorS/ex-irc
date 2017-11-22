defmodule ExIRC.Session.Supervisor do
  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def start_child(socket_pid) do
    child_spec = worker(ExIRC.Session, [socket_pid], [id: socket_pid, restart: :transient])

    Supervisor.start_child(__MODULE__, child_spec)
  end

  def init(_) do
    children = []

    supervise(children, strategy: :one_for_one)
  end
end
