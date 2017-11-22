defmodule ExIRC.Session do
  use GenServer

  require Logger

  alias ExIRC.Protocol
  alias ExIRC.Session

  # TODO: Fix this
  @host "localhost"
  @version "0.0.1"
  @server_name "andromeda"

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

  def finish_registration(pid, new_state) do
    GenServer.cast(pid, {:finish_registration, new_state})
  end

  # Server

  def init(socket) do
    Logger.info("Session starting, socket: #{inspect socket}")

    initial_state = %{
      socket: socket,
      nickname: nil,
      user: nil,
      host: nil,
      realname: nil,
      invisible: false,
      step: "registration"
    }

    {:ok, initial_state}
  end

  def handle_cast({:recv, "CAP LS"}, state) do
    Logger.info("Session received capabilities list request")

    message = "CAP * LS"

    echo(self(), message)

    {:noreply, state}
  end

  # TODO: Should wait on CAP END to process registration.
  def handle_cast({:recv, "CAP END"}, state) do
    {:noreply, state}
  end

  def handle_cast({:recv, "NICK " <> nickname}, %{step: "registration"} = state) do
    new_state = %{ state | nickname: nickname }

    finish_registration(self(), new_state)

    {:noreply, new_state}
  end

  def handle_cast({:recv, "USER " <> user_data}, %{step: "registration"} = state) do
    [user, _mode, _unused, ":" <> realname] = String.split(user_data)

    new_state = %{ state | user: user, realname: realname }

    finish_registration(self(), new_state)

    {:noreply, new_state}
  end

  def handle_cast({:finish_registration, %{nickname: nil}}, %{step: "registration"} = state) do
    {:noreply, state}
  end

  def handle_cast({:finish_registration, %{user: nil}}, %{step: "registration"} = state) do
    {:noreply, state}
  end

  def handle_cast({:finish_registration, %{nickname: nickname, user: _user}}, %{step: "registration"} = state) do
    echo(self(), "001 #{nickname} :Hi, welcome to IRC")
    echo(self(), "002 #{nickname} :Your host is #{@host}, running version ExIRC #{@version}")
    echo(self(), "003 #{nickname} :This server was created recently")
    echo(self(), "004 #{nickname} #{@server_name} ExIRC-#{@version} o o")

    new_state = %{ state | step: "registered"}

    {:noreply, new_state}
  end

  def handle_cast({:recv, "MODE " <> mode_data}, state) do
    # TODO: Check nickname against session nickname
    [_nickname, action] = String.split(mode_data)

    # TODO: handle more than invisible
    invisible = String.starts_with?(action, "+")

    new_state = %{ state | invisible: invisible }

    {:noreply, new_state}
  end

  def handle_cast({:recv, "PING " <> origin}, state) do
    # TODO: handle no origin
    echo(self(), "PONG #{@server_name} :#{origin}")

    {:noreply, state}
  end

  def handle_cast({:echo, message}, %{socket: socket} = state) do
    Logger.info("echoing message: #{inspect message}")

    Protocol.echo(socket, message)

    {:noreply, state}
  end
end
