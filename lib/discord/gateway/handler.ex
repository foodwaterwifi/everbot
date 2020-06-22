defmodule Discord.Gateway.Handler do
  require Discord.Opcodes, as: Opcodes

  def handle_message(message, state) do
    decoded = %{op: opcode} = :erlang.binary_to_term(message)

    {:ok, opcode_atom} =
      if Opcodes.is_error_opcode(opcode) do
        exit("Received opcode #{opcode}")
      else
        Opcodes.gateway_opcode_to_atom(opcode)
      end

    handle(opcode_atom, decoded, state)
  end

  def handle(:heartbeat, _message, state) do
    {:noreply, state}
  end
end
