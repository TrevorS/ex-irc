defmodule ExIRC.Utils.List do
  def prepend(list, element) do
    [ element | list]
  end

  def pluck(list, attribute) do
    Enum.map(list, fn(element) ->
      Map.get(element, attribute)
    end)
  end
end
