defmodule MockServer do
  use Plug.Router

  plug :match
  plug :dispatch

  get("/status/:status", do: send_resp(conn, String.to_integer(status), content_for(status)))
  get("/large-response", do: send_resp(conn, 200, String.duplicate("a", 1000_000)))

  get "/" do
    conn
    |> send_resp(200, "OK")
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
