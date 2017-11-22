defmodule ExIRCTest do
  use ExUnit.Case
  doctest ExIRC

  test "greets the world" do
    assert ExIRC.hello() == :world
  end
end
