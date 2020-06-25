defmodule Discord.Gateway.EventDispatcher do
  alias Discord.Opcodes, as: Opcodes
  alias Discord.Gateway.State, as: State

  alias Discord.Gateway.Events, as: Events
  # require Events.Ready

  def dispatch_event(event, state = %State{}) do
    event = %{op: opcode} = :erlang.binary_to_term(event)

    # dispatch(opcode, event)

    # {:ok, opcode_atom} =
    #   if Opcodes.is_error_opcode(opcode) do
    #     exit("Received opcode #{opcode}")
    #   else
    #     Opcodes.gateway_opcode_to_atom(opcode)
    #   end

    # dispatch(opcode_atom, decoded, state)
  end

  # def dispatch(:heartbeat, _message, state), do:

  # Dispatch
end
