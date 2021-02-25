defmodule MockServer do
  use Plug.Router

  plug :match
  plug :dispatch

  def start_agent do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def stop_agent do
    Agent.stop(__MODULE__)
  end

  def agent_get(fun) do
    Agent.get(__MODULE__, fun)
  end

  def count_for(id) do
    Agent.get(__MODULE__, fn count_map ->
      count_map[to_string(id)]
    end)
  end

  def inc(id) do
    id = to_string(id)

    Agent.update(__MODULE__, fn count_map ->
      Map.put(count_map, id, (count_map[id] || 0) + 1)
    end)
  end

  get("/status/:status", do: send_resp(conn, String.to_integer(status), content_for(status)))
  get("/large-response", do: send_resp(conn, 200, String.duplicate("a", 1000_000)))

  get "/" do
    conn
    |> send_resp(200, "OK")
  end

  get "/refs/:id/:status" do
    inc(id)

    Agent.update(__MODULE__, fn state ->
      key = {id, :headers}
      Map.put(state, key, [Map.new(conn.req_headers) | state[key] || []])
    end)

    send_resp(conn, String.to_integer(status), content_for(status))
  end

  get "/200ms_response" do
    Process.sleep(200)

    conn
    |> send_resp(200, "200ms response")
  end

  get "/sleep/:sleep_ms" do
    sleep_ms |> String.to_integer() |> Process.sleep()

    conn
    |> send_resp(200, "slow")
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end

  def content_for("204"), do: ""
  def content_for("304"), do: ""
  def content_for(status), do: "#{status} body"
end
