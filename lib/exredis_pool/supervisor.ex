defmodule ExredisPool.Supervisor do
  use Supervisor

  def pool_spec(name) do
    pool_args = [name: { :local, name },
                 worker_module: :eredis,
                 size_args: size_config]
    IO.puts("Redis config #{inspect(redis_config)}")
    :poolboy.child_spec({ :local, name }, pool_args, redis_config)
  end

  def start_link do
    :supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    children = [ pool_spec(ExredisPool.pool_name) ]
    supervise(children, strategy: :one_for_one)
  end

  def redis_config do
    if redis_url = System.get_env("REDIS_URL") do
      config = URI.parse(redis_url)
      [String.to_char_list(config.host), config.port, String.strip(config.path, ?/) |> String.to_integer]
    else
      ["127.0.0.1", 6379]
    end
  end

  def size_config do
    [size: System.get_env("REDIS_POOL_SIZE") || 10,
     max_overflow: System.get_env("REDIS_POOL_MAX") || 30 ]
  end
end
