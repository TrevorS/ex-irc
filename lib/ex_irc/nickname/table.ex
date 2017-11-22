defmodule ExIRC.Nickname.Table do
  alias ExIRC.Client

  @table __MODULE__

  def new do
    :ets.new(@table, [:named_table, :public])
  end

  def insert_or_update(nickname, %Client{} = client) do
    :ets.insert(@table, {nickname, client})
  end

  def delete(nickname) do
    :ets.match_delete(@table, {nickname, :"_"})
  end

  def lookup(nickname) do
    case :ets.match(@table, {nickname, :"$1"}) do
      [[client]] -> client
      [] -> nil
    end
  end
end
