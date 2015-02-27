defmodule ExredisPool.Mixfile do
  use Mix.Project

  def project do
    [ app: :exredis_pool,
      version: "0.0.1",
      elixir: "~> 1.0.2",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    [mod: { ExredisPool, [] },
     env: [
           size_args: [ size: System.get_env("REDIS_POOL_SIZE") || 10,
                        max_overflow: System.get_env("REDIS_POOL_MAX") || 30 ],
           redis_args: redis_config]
       ]
    ]
  end

  # Returns the list of dependencies in the format:
  # { :foobar, git: "https://github.com/elixir-lang/foobar.git", tag: "0.1" }
  #
  # To specify particular versions, regardless of the tag, do:
  # { :barbat, "~> 0.1", github: "elixir-lang/barbat" }
  defp deps do
    [
     { :eredis, github: "wooga/eredis" },
     { :poolboy, github: "devinus/poolboy" }
    ]
  end

  def redis_config do
    if redis_url = System.get_env("REDIS_URL") do
      config = URI.parse(redis_url)
      [config.host, config.port, String.strip(config.path, ?/)]
    else
      ["127.0.0.1", 6379]
    end
  end
end
