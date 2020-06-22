defmodule Discord.Opcodes do
  @doc """
    CODE	NAME	    CLIENT            ACTION	DESCRIPTION
    0	    Dispatch	Receive	          An event was dispatched.
    1	    Heartbeat	Send/Receive	    Fired periodically by the client to keep the connection alive.
    2	    Identify	Send	            Starts a new session during the initial handshake.
    3	    Presence  UpdateSend	      Update the client's presence.
    4	    Voice     StateUpdateSend	  Used to join/leave or move between voice channels.
    6	    Resume	  Send	            Resume a previous session that was disconnected.
    7	    Reconnect	Receive	          You should attempt to reconnect and resume immediately.
    8	    Request   GuildMembersSend	Request information about offline guild members in a large guild.
    9	    Invalid   SessionReceive	  The session has been invalidated. You should reconnect and identify/resume accordingly.
    10	  Hello   	Receive	          Sent immediately after connecting, contains the heartbeat_interval to use.
    11  	Heartbeat ACKReceive	      Sent in response to receiving a heartbeat to acknowledge that it has been received.

    CODE	DESCRIPTION	            EXPLANATION
    4000	Unknown error	          We're not sure what went wrong. Try reconnecting?
    4001	Unknown opcode	        You sent an invalid Gateway opcode or an invalid payload for an opcode. Don't do that!
    4002	Decode error	          You sent an invalid payload to us. Don't do that!
    4003	Not authenticated	      You sent us a payload prior to identifying.
    4004	Authentication failed	  The account token sent with your identify payload is incorrect.
    4005	Already authenticated	  You sent more than one identify payload. Don't do that!
    4007	Invalid seq	            The sequence sent when resuming the session was invalid. Reconnect and start a new session.
    4008	Rate limited	          Woah nelly! You're sending payloads to us too quickly. Slow it down! You will be disconnected on receiving this.
    4009	Session timed out	      Your session timed out. Reconnect and start a new one.
    4010	Invalid shard	          You sent us an invalid shard when identifying.
    4011	Sharding required	      The session would have handled too many guilds - you are required to shard your connection in order to connect.
    4012	Invalid API version	    You sent an invalid version for the gateway.
    4013	Invalid intent(s)	      You sent an invalid intent for a Gateway Intent. You may have incorrectly calculated the bitwise value.
    4014	Disallowed intent(s)	  You sent a disallowed intent for a Gateway Intent. You may have tried to specify an intent that you have not enabled or are not whitelisted for.
  """
  @gateway_opcodes %{
    0 => :dispatch,
    1 => :heartbeat,
    2 => :identify,
    3 => :presence_update,
    4 => :voice_state_update,
    6 => :resume,
    7 => :reconnect,
    8 => :request_guild_members,
    9 => :invalid_session,
    10 => :hello,
    11 => :heartbeat_ack,
    4000 => :unknown_error,
    4001 => :unknown_opcode,
    4002 => :decode_error,
    4003 => :not_authenticated,
    4004 => :authentication_failed,
    4005 => :already_authenticated,
    4007 => :invalid_seq,
    4008 => :rate_limited,
    4009 => :session_timed_out,
    4010 => :invalid_shard,
    4011 => :sharding_required,
    4012 => :invalid_api_session,
    4013 => :invalid_intent,
    4014 => :disallowed_intent
  }

  @gateway_opcodes_rev Enum.reduce(Map.keys(@gateway_opcodes), %{}, fn key, acc ->
                         Map.put(acc, Map.fetch!(@gateway_opcodes, key), key)
                       end)

  def gateway_opcode_to_atom(opcode), do: Map.fetch(@gateway_opcodes, opcode)
  def gateway_atom_to_opcode(atom), do: Map.fetch(@gateway_opcodes_rev, atom)

  def is_error_opcode(opcode) do
    opcode >= 4000
  end
end
