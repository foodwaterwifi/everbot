defmodule Discord.Gateway.ServerMacros do
  defmacro invalid_stream_guard(name) do
    quote do
      def unquote(name)(state = %Discord.Gateway.State{stream_ref: stream_ref}, last_stream_ref)
          when is_nil(stream_ref) or stream_ref != last_stream_ref,
          do: {:noreply, state}
    end
  end

  defmacro invalid_stream_or_session_guard(name) do
    quote do
      def unquote(name)(
            state = %Discord.Gateway.State{stream_ref: stream_ref, session_id: session_id},
            last_stream_ref,
            last_session_id
          )
          when is_nil(stream_ref) or is_nil(session_id) or stream_ref != last_stream_ref or
                 session_id != last_session_id,
          do: {:noreply, state}
    end
  end
end
