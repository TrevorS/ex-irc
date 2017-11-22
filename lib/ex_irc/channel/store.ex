defmodule ExIRC.Channel.Store do
  use GenServer

  alias ExIRC.Channel
  alias ExIRC.Channel.Table

  @name __MODULE__

  # Client

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: @name)
  end

  def lookup(name) do
    Table.lookup(name)
  end

  def insert_or_update(%Channel{name: name} = channel) do
    GenServer.call(@name, {:insert_or_update, name, channel})
  end

  def delete(%Channel{name: name}) do
    GenServer.call(@name, {:delete, name})
  end

  # Server

  def init(_) do
    Table.new()

    {:ok, nil}
  end

  def handle_call({:insert_or_update, name, channel}, _from, state) do
    result = Table.insert_or_update(name, channel)

    {:reply, result, state}
  end

  def handle_call({:delete, name}, _from, state) do
    result = Table.delete(name)

    {:reply, result, state}
  end
end
