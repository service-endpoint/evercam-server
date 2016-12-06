defmodule EvercamMedia.Snapmail.Snapmailer do
  @moduledoc """
  Provides functions to send schedule snapmail
  """

  use GenServer
  alias EvercamMedia.Snapshot.CamClient

  ################
  ## Client API ##
  ################

  @doc """
  Start the Snapmail server for a given snapmail.
  """
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: args[:name])
  end

  @doc """
  Get the state of the snapmail worker.
  """
  def get_state(snapmail_server) do
    GenServer.call(snapmail_server, :get_state)
  end

  @doc """
  Get the configuration of the snapmail worker.
  """
  def get_config(snapmail_server) do
    GenServer.call(snapmail_server, :get_snapmail_config)
  end

  @doc """
  Update the configuration of the snapmail worker
  """
  def update_config(snapmail_server, config) do
    GenServer.cast(snapmail_server, {:update_snapmail_config, config})
  end

  @doc """
  Get a snapshot from the camera and send snapmail
  """
  def get_snapshot(cam_server, {:poll, timestamp}) do
    GenServer.cast(cam_server, {:get_camera_snapshot, timestamp})
  end

  ######################
  ## Server Callbacks ##
  ######################

  @doc """
  Initialize the snapmail server
  """
  def init(args) do
    {:ok, event_manager} = GenEvent.start_link
    {:ok, poller} = EvercamMedia.Snapmail.Poller.start_link(args)
    add_handlers(event_manager, args[:event_handlers])
    args = Map.merge args, %{
      poller: poller,
      event_manager: event_manager
    }
    {:ok, args}
  end

  @doc """
  Server callback for restarting snapmail poller
  """
  def handle_call(:restart_snapmail_poller, _from, state) do
    {:reply, nil, state}
  end

  @doc """
  Server callback for stopping snapmail poller
  """
  def handle_call(:stop_snapmail_poller, _from, state) do
    {:reply, nil, state}
  end

  @doc """
  Server callback for getting snapmail config
  """
  def handle_call(:get_snapmail_config, _from, state) do
    {:reply, get_config_from_state(:config, state), state}
  end

  @doc """
  Server callback for getting worker state
  """
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @doc """
  """
  def handle_cast({:get_camera_snapshot, timestamp}, state) do
    _get_snapshot(state, timestamp)
    {:noreply, state}
  end

  @doc """
  Server callback for camera_reply
  """
  def handle_info({:camera_reply, image, timestamp}, state) do
    data = {state.config.camera_exid, timestamp, image}
    GenEvent.sync_notify(state.event_manager, {:got_snapshot, data})
    {:noreply, state}
  end

  @doc """
  Take care of unknown messages which otherwise would trigger function clause mismatch error.
  """
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  #####################
  # Private functions #
  #####################

  defp add_handlers(event_manager, event_handlers) do
    Enum.each(event_handlers, &GenEvent.add_mon_handler(event_manager, &1,[]))
  end

  defp get_config_from_state(:config, state) do
    Map.get(state, :config)
  end

  defp _get_snapshot(state, timestamp) do
    config = get_config_from_state(:config, state)
    camera_exid = config.camera_exid
    worker = self
    try_snapshot(state, config, camera_exid, timestamp, worker)
  end

  defp try_snapshot(state, config, camera_exid, timestamp, worker) do
    camera = Camera.get(camera_exid)
    spawn fn ->
      case CamClient.fetch_snapshot(config) do
        {:ok, image} ->
          EvercamMedia.UserMailer.snapmail(state.config.notify_time, state.config.recipients, camera, image)
          send worker, {:camera_reply, image, timestamp}
        {:error, _error} ->
          EvercamMedia.UserMailer.snapmail(state.config.notify_time, state.config.recipients, camera, nil)
      end
    end
  end
end
