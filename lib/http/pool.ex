defmodule HTTP.Pool do
  require Logger

  def request(method, url, headers, body) do
    uri = URI.parse(url)
    # TODO: handle errors
    {:ok, pool} = get_or_create_pool(uri)
  end

  def get_or_create_pool(uri) do
    case get_pool(uri) do
      {:ok, pool}  -> {:ok, pool}
      :not_found -> create_pool(uri)
    end
  end

  defp create_pool(uri) do
    # TODO: dig into configuration for http1/http2 info before making a connection
    case Mint.HTTP.connect(scheme(uri.scheme), uri.host, uri.port) do
      {:ok, conn = %Mint.HTTP1{}} ->
        # TODO: Ideally, we should forward the connection to the pool, but at this
        # time we just open a connection to find the server's protocol
        Mint.HTTP.close(conn)
        create_http1_pool(uri)
      {:ok, conn = %Mint.HTTP2{}} ->
        # TODO: Ideally, we should forward the connection to the pool, but at this
        # time we just open a connection to find the server's protocol
        Mint.HTTP.close(conn)
        create_http2_pool(uri)
      error -> error
    end
  end

  defp create_http1_pool(uri) do
  end

  defp create_http2_pool(uri) do
  end

  defp get_pool(uri) do
    case pool_for(uri) do
      [{pool, _}] -> {:ok, pool}
      [] -> :not_found
      err ->
        Logger.error error: err, uri: uri, code: "UNEXPECTED_REGISTRY_LOOKUP"
    end
  end

  # Finds the pool for the given uri
  defp pool_for(uri) do
    # Pool changes if any of the scheme / host / port change :(
    # e.g. http://putty.minhajuddin.com or https://putty.minhajuddin.com or http://putty.minhajuddin.com:8080
    Registry.lookup HTTP.Registry, pool_id(uri) 
  end

  defp pool_id(uri = %URI{}) do
    {uri.scheme, uri.host, uri.port}
  end

  defp scheme("https"), do: :https
  defp scheme("http"), do: :http
end
