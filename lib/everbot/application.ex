defmodule Everbot.Application do
  require Everbot
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Everbot.Worker.start_link(arg)
      # {Everbot.Worker, arg}
    ]

    Everbot.hello()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Everbot.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
