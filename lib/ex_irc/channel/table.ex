defmodule ExIRC.Channel.Table do
  alias ExIRC.Channel

  @table __MODULE__

  def new do
    :ets.new(@table, [:named_table])
  end

  def insert_or_update(name, %Channel{} = channel) do
    :ets.insert(@table, {name, channel})
  end

  def delete(name) do
    :ets.match_delete(@table, {name, :"_"})
  end

  def lookup(name) do
    case :ets.match(@table, {name, :"$1"}) do
      [[channel]] -> channel
      [] -> nil
    end
  end
end
