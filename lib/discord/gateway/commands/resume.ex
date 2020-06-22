defmodule Discord.Gateway.Commands.Resume do
  def new(_state = %{bot_token: bot_token, session_id: session_id, seq: seq}) do
    %{
      op: 6,
      d: %{
        token: bot_token,
        session_id: session_id,
        seq: seq
      }
    }
  end
end
