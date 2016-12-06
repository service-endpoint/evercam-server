defmodule EvercamMedia do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(ConCache, [[ttl_check: :timer.seconds(0.1), ttl: :timer.seconds(2.5)], [name: :cache]]),
      worker(ConCache, [[ttl_check: :timer.seconds(0.1), ttl: :timer.seconds(1.5)], [name: :snapshot_schedule]], id: :snapshot_schedule),
      worker(ConCache, [[ttl_check: :timer.seconds(0.1), ttl: :timer.minutes(1)], [name: :camera_lock]], id: :camera_lock),
      worker(ConCache, [[ttl_check: :timer.seconds(1), ttl: :timer.hours(1)], [name: :users]], id: :users),
      worker(ConCache, [[ttl_check: :timer.seconds(1), ttl: :timer.hours(1)], [name: :camera]], id: :camera),
      worker(ConCache, [[ttl_check: :timer.seconds(1), ttl: :timer.hours(1)], [name: :cameras]], id: :cameras),
      worker(ConCache, [[ttl_check: :timer.seconds(1), ttl: :timer.hours(1)], [name: :camera_full]], id: :camera_full),
      worker(ConCache, [[ttl_check: :timer.hours(1), ttl: :timer.hours(24)], [name: :snapshot_error]], id: :snapshot_error),
      supervisor(EvercamMedia.Repo, []),
      supervisor(EvercamMedia.Endpoint, []),
      supervisor(EvercamMedia.SnapshotRepo, []),
      supervisor(EvercamMedia.Snapshot.Storage.Export.PoolSupervisor, []),
      supervisor(EvercamMedia.Snapshot.Storage.Export.Supervisor, []),
      supervisor(EvercamMedia.Snapshot.StreamerSupervisor, []),
      supervisor(EvercamMedia.Snapshot.WorkerSupervisor, []),
      supervisor(EvercamMedia.Snapmail.SnapmailerSupervisor, []),
      :hackney_pool.child_spec(:snapshot_pool, [timeout: 5000, max_connections: 1000]),
      :hackney_pool.child_spec(:seaweedfs_upload_pool, [timeout: 10_000, max_connections: 5000]),
      :hackney_pool.child_spec(:seaweedfs_download_pool, [timeout: 10_000, max_connections: 5000]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EvercamMedia.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    EvercamMedia.Endpoint.config_change(changed, removed)
    :ok
  end
end
