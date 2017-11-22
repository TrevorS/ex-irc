defmodule ExIRC.Config do
  def port, do:
    Application.get_env(:ex_irc, :port)
end
