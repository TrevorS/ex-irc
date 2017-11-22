defmodule ExIRC.Session do
  use GenServer

  require Logger

  alias ExIRC.Protocol
  alias ExIRC.Session
  alias ExIRC.Client

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

  def finish_registration(pid, new_client) do
    GenServer.cast(pid, {:finish_registration, new_client})
  end

  # Server

  def init(socket) do
    Logger.info("Session starting, socket: #{inspect socket}")

    client = Client.new(socket: socket)

    {:ok, client}
  end

  def handle_cast({:recv, "CAP LS"}, client) do
    Logger.info("Session received capabilities list request")

    message = "CAP * LS"

    echo(self(), message)

    {:noreply, client}
  end

  # TODO: Should wait on CAP END to process registration.
  def handle_cast({:recv, "CAP END"}, client) do
    {:noreply, client}
  end

  def handle_cast({:recv, "NICK " <> nickname}, %{step: "registration"} = client) do
    new_client = Client.set_nickname(client, nickname)

    finish_registration(self(), new_client)

    {:noreply, new_client}
  end

  def handle_cast({:recv, "USER " <> user_data}, %{step: "registration"} = client) do
    [user, _mode, _unused, ":" <> realname] = String.split(user_data)

    new_client =
      client
      |> Client.set_user(user)
      |> Client.set_realname(realname)

    finish_registration(self(), new_client)

    {:noreply, new_client}
  end

  def handle_cast({:finish_registration, %{nickname: nil}}, %{step: "registration"} = client) do
    {:noreply, client}
  end

  def handle_cast({:finish_registration, %{user: nil}}, %{step: "registration"} = client) do
    {:noreply, client}
  end

  def handle_cast({:finish_registration, %{nickname: nickname, user: _user}}, %{step: "registration"} = client) do
    echo(self(), "001 #{nickname} :Hi, welcome to IRC")
    echo(self(), "002 #{nickname} :Your host is #{@host}, running version ExIRC #{@version}")
    echo(self(), "003 #{nickname} :This server was created recently")
    echo(self(), "004 #{nickname} #{@server_name} ExIRC-#{@version} o o")

    new_client = Client.set_registered(client)

    {:noreply, new_client}
  end

  def handle_cast({:recv, "MODE " <> mode_data}, client) do
    # TODO: Check nickname against session nickname
    [_nickname, action] = String.split(mode_data)

    # TODO: handle more than invisible
    invisible = String.starts_with?(action, "+")

    new_client = Client.set_invisible(client, invisible)

    {:noreply, new_client}
  end

  def handle_cast({:recv, "PING " <> origin}, client) do
    # TODO: handle no origin
    echo(self(), "PONG #{@server_name} :#{origin}")

    {:noreply, client}
  end

  def handle_cast({:echo, message}, %{socket: socket} = client) do
    Logger.info("echoing message: #{inspect message}")

    Protocol.echo(socket, message)

    {:noreply, client}
  end
end
