defmodule HTTP do
  require Logger

  # TODO: Use defdelegate
  def request(method, url, headers \\ [], body \\ nil, _receive_timeout \\ nil) do
    HTTP.Pool.request(method, url, headers, body)
  end

  # TODO: remove finch
  # TODO: these should be read from the input request payload or config

  # @receive_timeout 100
  # @pool_timeout 1
  #
  # def request(method, url, headers \\ [], body \\ nil, receive_timeout \\ nil) do
    # try do
      # Finch.build(method, url, headers, body)
      # |> Finch.request(HAFinch,
        # receive_timeout: receive_timeout || @receive_timeout,
        # pool_timeout: @pool_timeout
  # )
    # rescue
      # err -> {:error, err}
    # end
  # end
end
