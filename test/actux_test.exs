defmodule ActuxTest do
  use ExUnit.Case
  doctest Actux

  test "greets the world" do
    assert Actux.hello() == :world
  end
end
