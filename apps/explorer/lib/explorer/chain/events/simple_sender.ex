defmodule Explorer.Chain.Events.SimpleSender do
  @moduledoc """
  Publishes events through Registry without intermediate levels.
  """

  require Logger

  def send_data(event_type, broadcast_type, event_data) do
    Registry.dispatch(Registry.ChainEvents, {event_type, broadcast_type}, fn entries ->
      for {pid, _registered_val} <- entries do
        send(pid, {:chain_event, event_type, broadcast_type, event_data})
        Logger.info("Explorer.Chain.Events.SimpleSender published event with event_type #{event_type} and event_data #{event_data}")
      end
    end)
  end

  def send_data(event_type) do
    Registry.dispatch(Registry.ChainEvents, event_type, fn entries ->
      for {pid, _registered_val} <- entries do
        send(pid, {:chain_event, event_type})
        Logger.info("Explorer.Chain.Events.SimpleSender published event with event_type #{event_type}")
      end
    end)
  end
end
