defmodule ExIRC.Nickname.Store do
  use GenServer

  alias ExIRC.Client
  alias ExIRC.Nickname.Table

  @name __MODULE__

  # Client

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: @name)
  end

  def lookup(socket) do
    Table.lookup(socket)
  end

  def insert_or_update(%Client{nickname: nickname} = client) do
    GenServer.call(@name, {:insert_or_update, nickname, client})
  end

  def delete(%Client{nickname: nickname}) do
    GenServer.call(@name, {:delete, nickname})
  end

  # Server

  def init(_) do
    Table.new()

    {:ok, nil}
  end

  def handle_call({:insert_or_update, nickname, client}, _from, state) do
    result = Table.insert_or_update(nickname, client)

    {:reply, result, state}
  end

  def handle_call({:delete, nickname}, _from, state) do
    result = Table.delete(nickname)

    {:reply, result, state}
  end
end
