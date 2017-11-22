defmodule ExIRC.Channel do
  alias ExIRC.Utils

  defstruct name: nil, members: [], topic: nil

  def new(name: name) do
    %__MODULE__{name: name}
  end

  def set_topic(channel, topic) do
    %{ channel | topic: topic }
  end

  def add_member(channel, client) do
    update_in(channel.members, &Utils.List.prepend(&1, client))
  end

  def remove_member(channel, client) do
    update_in(channel.members, &List.delete(&1, client))
  end
end
