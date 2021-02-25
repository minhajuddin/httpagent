defmodule HA.HTTP do
  require Logger

  defmodule Request do
    alias __MODULE__

    defstruct method: :get,
              url: nil,
              headers: [],
              body: nil,
              receive_timeout: nil,
              retry: 3,
              idempotency_key: nil,
              follow_redirects: true

    def build(attrs = []) do
      struct(__MODULE__, attrs)
    end

    def set_idempotency_key(%Request{idempotency_key: nil} = req) do
      %{req | idempotency_key: :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)}
    end

    def set_idempotency_key(req), do: req
  end

  # TODO: these should be read from the input request payload or config
  @receive_timeout 100
  @pool_timeout 1

  def request(%Request{} = request) do
    request = Request.set_idempotency_key(request)

    case _request(request) do
      {:ok, resp} when resp.status >= 500 and request.retry > 0 ->
        # TODO: emit telemetry
        Logger.debug(request: request, code: "RETRYING")
        request(%{request | retry: request.retry - 1})

      {:ok, resp} ->
        # TODO: emit telemetry
        {:ok, resp}

      {:error, err} when request.retry > 0 ->
        # TODO: emit telemetry
        Logger.debug(request: request, code: "RETRYING", err: err)
        request(%{request | retry: request.retry - 1})

      {:error, err} ->
        # TODO: emit telemetry
        {:error, err}
    end
  end

  def request(method, url, headers \\ [], body \\ nil, receive_timeout \\ nil) do
    Logger.warn("[DEPRECATED] Use request/1")

    %Request{
      method: method,
      url: url,
      headers: headers,
      body: body,
      receive_timeout: receive_timeout
    }
    |> request
  end

  @idempotency_key_header "idempotency-key"
  def _request(request) do
    try do
      Finch.build(
        request.method,
        request.url,
        request.headers ++ [{@idempotency_key_header, request.idempotency_key}],
        request.body
      )
      |> Finch.request(HAFinch,
        receive_timeout: request.receive_timeout || @receive_timeout,
        pool_timeout: @pool_timeout
      )
    rescue
      err -> {:error, err}
    end
  end
end
