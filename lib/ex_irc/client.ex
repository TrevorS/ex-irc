defmodule ExIRC.Client do
  alias ExIRC.Utils

  defstruct socket: nil, nickname: nil, user: nil, host: nil,
    channels: [], realname: nil, invisible: false, step: "registration"

  def new(socket: socket) do
    %__MODULE__{socket: socket}
  end

  def set_nickname(client, nickname) do
    %{ client | nickname: nickname }
  end

  def set_user(client, user) do
    %{ client | user: user }
  end

  def set_realname(client, realname) do
    %{ client | realname: realname }
  end

  def set_invisible(client, invisible) do
    %{ client | invisible: invisible }
  end

  def set_registered(client) do
    %{ client | step: "registered" }
  end

  def add_channel(client, channel) do
    update_in(client.channels, &Utils.List.prepend(&1, channel))
  end

  def remove_channel(client, channel) do
    update_in(client.channels, &List.delete(&1, channel))
  end
end
