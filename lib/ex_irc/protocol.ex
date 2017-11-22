defmodule ExIRC.Protocol do
  use GenServer

  require Logger

  alias ExIRC.Session

  @behaviour :ranch_protocol

  # Client

  def start_link(ref, socket, transport, _opts) do
    pid = :proc_lib.spawn_link(__MODULE__, :init, [ref, socket, transport])

    {:ok, pid}
  end

  def echo(socket, message) do
    GenServer.cast(socket, {:echo, message})
  end

  # Server

  def init(ref, socket, transport) do
    Logger.info "Connecting, socket: #{inspect socket}"

    :ok = :ranch.accept_ack(ref)

    :ok = transport.setopts(socket, [active: true])

    GenServer.cast(self(), :start_session)

    :gen_server.enter_loop(__MODULE__, [], %{socket: socket, transport: transport})
  end

  def handle_cast(:start_session, state) do
    Logger.info("In start session, state: #{inspect state}")

    {:ok, pid} = Session.start(self())

    {:noreply, Map.merge(state, %{session: pid})}
  end

  def handle_cast({:echo, message}, state) do
    data = "\n#{message}\n"

    send_data(state, data)

    {:noreply, state}
  end

  def handle_info({:tcp, _socket, data}, state) do
    case state do
      %{session: pid} ->
        message = String.trim(data)

        Session.recv(pid, message)
      _ ->
        Logger.info("state: #{inspect state}")
        Logger.info("data: #{inspect data}")
    end

    {:noreply, state}
  end

  def handle_info({:tcp_closed, socket}, state) do
    Logger.info("Socket closed: #{inspect socket}")
    Logger.info("State: #{inspect state}")

    {:noreply, state}
  end

  defp send_data(%{socket: socket, transport: transport}, data) do
    transport.send(socket, data)
  end
end
