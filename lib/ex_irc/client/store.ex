defmodule ExIRC.Client.Store do
  use GenServer

  alias ExIRC.Client
  alias ExIRC.Client.Table

  @name __MODULE__

  # Client

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: @name)
  end

  def lookup(socket) do
    Table.lookup(socket)
  end

  def insert(%Client{socket: socket} = client) do
    GenServer.call(@name, {:insert, socket, client})
  end

  def delete(%Client{socket: socket}) do
    GenServer.call(@name, {:delete, socket})
  end

  # Server

  def init(_) do
    Table.new()

    {:ok, nil}
  end

  def handle_call({:insert, socket, client}, _from, state) do
    result = Table.insert(socket, client)

    {:reply, result, state}
  end

  def handle_call({:delete, socket}, _from, state) do
    result = Table.delete(socket)

    {:reply, result, state}
  end
end
