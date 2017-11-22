defmodule ExIRC.Client.Table do
  alias ExIRC.Client

  @table __MODULE__

  def new do
    :ets.new(@table, [:named_table])
  end

  def insert(socket, %Client{} = client) do
    :ets.insert_new(@table, {socket, client})
  end

  def delete(socket) do
    :ets.match_delete(@table, {socket, :"_"})
  end

  def lookup(socket) do
    case :ets.match(@table, {socket, :"$1"}) do
      [[client]] -> client
      [] -> nil
    end
  end
end
