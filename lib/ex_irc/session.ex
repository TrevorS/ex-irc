defmodule ExIRC.Session do
  use GenServer

  require Logger

  alias ExIRC.Protocol
  alias ExIRC.Session

  # Client

  def start(socket) do
    Session.Supervisor.start_child(socket)
  end

  def start_link(socket) do
    GenServer.start_link(__MODULE__, socket)
  end

  def recv(pid, message) do
    GenServer.cast(pid, {:recv, message})
  end

  def echo(pid, message) do
    GenServer.cast(pid, {:echo, message})
  end

  # Server

  def init(socket) do
    Logger.info("Session starting, socket: #{inspect socket}")

    {:ok, %{socket: socket}}
  end

  def handle_cast({:recv, message}, state) do
    Logger.info("received message: #{inspect message}")

    echo(self(), message)

    {:noreply, state}
  end

  def handle_cast({:echo, message}, %{socket: socket} = state) do
    Logger.info("echoing message: #{inspect message}")

    Protocol.echo(socket, message)

    {:noreply, state}
  end
end
