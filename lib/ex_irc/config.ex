defmodule ExIRC.Config do
  def port, do:
    Application.get_env(:ex_irc, :port)

  def server_name, do:
    Application.get_env(:ex_irc, :server_name)

  def hostname do
    {:ok, hostname} = :inet.gethostname()

    hostname
  end

  def version do
    {:ok, version} = :application.get_key(:ex_irc, :vsn)

    to_string(version)
  end
end
