defmodule ExIRC.Session do
  use GenServer

  require Logger

  alias ExIRC.Client
  alias ExIRC.Config
  alias ExIRC.Protocol
  alias ExIRC.Session
  alias ExIRC.Channel
  alias ExIRC.Utils

  alias ExIRC.Client.Store, as: CS
  alias ExIRC.Nickname.Store, as: NS
  alias ExIRC.Channel.Store, as: CNS

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

  def names(pid, channel_names_string) do
    GenServer.cast(pid, {:names, channel_names_string})
  end

  # Server

  def init(socket) do
    Logger.info("Session starting, socket: #{inspect socket}")

    new_client = Client.new(socket: socket)

    update_stores(new_client)

    {:ok, new_client}
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

    update_stores(new_client)

    finish_registration(self(), new_client)

    {:noreply, new_client}
  end

  def handle_cast({:recv, "USER " <> user_data}, %{step: "registration"} = client) do
    [user, _mode, _unused, ":" <> realname] = String.split(user_data)

    new_client =
      client
      |> Client.set_user(user)
      |> Client.set_realname(realname)

    update_stores(new_client)

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
    echo(self(), "002 #{nickname} :Your host is #{Config.hostname()}, running version ExIRC #{Config.version()}")
    echo(self(), "003 #{nickname} :This server was created recently")
    echo(self(), "004 #{nickname} #{Config.server_name()} ExIRC-#{Config.version()} o o")

    new_client = Client.set_registered(client)

    update_stores(new_client)

    {:noreply, new_client}
  end

  def handle_cast({:recv, "MODE #" <> mode_data}, client) do
    # TODO: Handle setting and getting channel modes
    message = "324 #{client.nickname} #{mode_data}"

    echo(self(), message)

    {:noreply, client}
  end

  def handle_cast({:recv, "MODE " <> mode_data}, client) do
    # TODO: Handle channel modes
    # TODO: Check nickname against session nickname
    [_nickname, action] = String.split(mode_data)

    # TODO: handle more than invisible
    invisible = String.starts_with?(action, "+")

    new_client = Client.set_invisible(client, invisible)

    update_stores(new_client)

    {:noreply, new_client}
  end

  def handle_cast({:recv, "PING " <> origin}, client) do
    # TODO: handle no origin
    echo(self(), "PONG #{Config.server_name()} :#{origin}")

    {:noreply, client}
  end

  # TODO: handle QUIT

  def handle_cast({:recv, "JOIN " <> channel_name}, client) do
    Logger.info("#{client.nickname} is joining #{channel_name}")
    # TODO: handle case insensitive channel names
    new_channel =
      case CNS.lookup(channel_name) do
        nil ->
          Channel.new(name: channel_name)
        channel ->
          channel
      end |> Channel.add_member(client)

    new_client = Client.add_channel(client, new_channel)

    update_stores(new_client, new_channel)

    message =
      case new_channel.topic do
        nil -> "331 #{client.nickname} #{new_channel.name} :No topic is set"
        topic -> "332 #{client.nickname} #{new_channel.name} :#{topic}"
      end

    echo(self(), message)

    names(self(), new_channel.name)

    {:noreply, new_client}
  end

  def handle_cast({:names, channel_names_string}, client) do
    # TODO properly handle multiple channels and no channels
    channel_names = String.split(channel_names_string, ", ")

    channel_name = List.first(channel_names)

    channel = CNS.lookup(channel_name)

    message_prefix = "353 #{client.nickname} = #{channel.name} :"

    IO.inspect(channel.members, label: "channel members")

    names =
      channel.members
      |> Utils.List.pluck(:nickname)
      |> Enum.join(" ")

    message = "#{message_prefix}#{names}"

    message_end = "366 #{client.nickname} #{channel.name} :End of NAMES list"

    echo(self(), message)
    echo(self(), message_end)

    {:noreply, client}
  end

  def handle_cast({:echo, message}, %{socket: socket} = client) do
    Logger.info("echoing message: #{inspect message}")

    Protocol.echo(socket, message)

    {:noreply, client}
  end

  defp update_stores(%Client{nickname: nickname} = new_client)
    when is_nil(nickname), do: CS.insert_or_update(new_client)

  defp update_stores(%Client{} = new_client) do
    CS.insert_or_update(new_client)
    NS.insert_or_update(new_client)
  end

  defp update_stores(%Client{} = new_client, %Channel{} = new_channel) do
    CS.insert_or_update(new_client)
    NS.insert_or_update(new_client)
    CNS.insert_or_update(new_channel)
  end
end
