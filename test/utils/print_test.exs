defmodule Everbot.Utils.PrintTest do
  use ExUnit.Case
  require Everbot.Utils.Print, as: Print
  doctest Everbot

  test "printing list" do
    assert Print.out([1, 2, 3, 4]) == "[1, 2, 3, 4]"
  end
end
