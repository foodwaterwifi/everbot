defmodule Discord.Gateway.Events.Ready do
  @moduledoc """
    FIELD	            TYPE	                                        DESCRIPTION
    v	                integer	                                      gateway version
    user	            user object	                                  information about the user including email
    private_channels	array	                                        empty array
    guilds	          array of Unavailable Guild objects	          the guilds the user is in
    session_id	      string	                                      used for resuming connections
    shard?	          array of two integers (shard_id, num_shards)	the shard information associated with this session, if sent when identifying
  """

  defstruct v: nil,
            user: nil,
            private_channels: nil,
            guilds: nil,
            session_id: nil,
            shard: nil
end
