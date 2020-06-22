defmodule EverbotTest do
  use ExUnit.Case
  doctest Everbot

  test "greets the world" do
    assert Everbot.hello() == :world
  end
end
