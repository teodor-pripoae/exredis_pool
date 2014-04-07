# ExredisPool

An elixir library to access redis via a pool of workers. Provides
convenient mechanisms to safely perform pipelines and transactions.

## Dependencies

- [eredis](https://github.com/wooga/eredis)
- [poolboy](https://github.com/devinus/poolboy)

## Configuration

The following options are available to configure `exredis_pool`:

1. `size_args` - should contain `size` and `max_overflow` fields
2. `redis_args` - a list of args that will be forwarded directly to `eredis`

### Example

In the `exredis_pool/mix.exs`:

```elixir
def application do
  [mod: { ExredisPool, [] },
   env: [
          size_args: [ size: 10,
                       max_overflow: 30 ],
          redis_args: [ "127.0.0.1", 6379 ]
      ]
   ]
end
```

## Usage

All functions are generated at compile time from a list of command
data found in `lib/exredis_pool.ex`. Each command is given as a key
and an argument specification. If a single integer is given, this
denotes the arity of the function. For example, `hincrby: 3` will
produce the function `ExredisPool.hincrby/3` which can be used to call
the redis command `HINCRBY key field incr`.

The special values "1n" and "2n" in the argument specifications denote
a variadic argument that are lists of singletons or pairs
respectively. For example, the function generated by `hmset:
[1, "2n"]` will accept a single argument followed by a list of
elements following the patter `[k1, v1, k2, v2, ...]`.

In this manner, nearly all the commands in Redis can be described
natively and the appropriate queries will be constructed.

### Transactions

Issuing a transaction in `exredis_pool` is extremely easy. This will
be illustrated with an example:

```elixir
ExredisPool.set("f", 3)
res = ExredisPool.multi |> ExredisPool.set("d", 1)
                        |> ExredisPool.set("e", 2)
                        |> ExredisPool.get("f")
                        |> ExredisPool.exec
# res will contain { :ok, [ "OK", "OK", "3" ] }
```

This will set the values of 2 keys and get the value of the key `"f"`.
The interface for each individual component of the transaction has the
same interface as before. The trick, of course, is that there is a
hidden parameter threaded through each call which builds a query to be
pipelined later on. It is important when performing a transaction that
it be opened with a `multi/0` and closed with an `exec/1` as shown
above to control this hidden parameter correctly.

Of course, you can use `watch/1` functionality as part of the pipeline
by simply chaining it in order to abort the transaction early if the
set of watched keys changes.

### Pipelining

In the event that you wish to batch commands together but you do not
need them to be performed in a transaction, you may use the pipeline
functionality instead.

```elixir
ExredisPool.set("f", 3)
res = ExredisPool.pipe |> ExredisPool.set("d", 1)
                       |> ExredisPool.set("e", 2)
                       |> ExredisPool.get("f")
                       |> ExredisPool.line
# res will contain [ { :ok, "OK", { :ok, "OK"}, { :ok, "3" } ] }
```

This resembles the transaction syntax, albeit with different function
delimiters. The results are also segmented in list form as opposed to
being consolidated in a single list element.
