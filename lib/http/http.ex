defmodule HA.HTTP do
  require Logger

  def request(method, url, headers \\ [], body \\ nil) do
    try do
      Finch.build(method, url, headers, body)
      |> Finch.request(HAFinch)
    rescue
      err -> {:error, err}
    end
  end
end
