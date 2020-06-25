defmodule Discord.Gateway.Commands.Heartbeat do
  @moduledoc """
    Used to maintain an active gateway connection. Must be sent every heartbeat_interval milliseconds
    after the Opcode 10 Hello payload is received. The inner d key is the last sequence number—s—received
    by the client. If you have not yet received one, send null.
  """
  def new(_state = %{seq: seq}) do
    %{
      "op" => 1,
      "d" => seq
    }
  end
end
