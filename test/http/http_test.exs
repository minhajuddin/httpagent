defmodule HA.HTTPTest do
  use HA.DataCase

  alias HA.HTTP
  alias HA.HTTP.Request
  require Logger

  @test_port 4032
  def test_url(path), do: "http://localhost:#{@test_port}/#{path}"

  setup_all do
    MockServer.start_agent()
    Plug.Cowboy.http(MockServer, [], port: @test_port)

    on_exit(fn ->
      Plug.Cowboy.shutdown(MockServer.HTTP)
    end)
  end

  describe "error conditions return an error response" do
    test "when url is invalid" do
      for url <- ~w[
        htts://this-is-a-non-existent-domain.nonexistentdomain
        hs://this-is-a-non-existent-domain.nonexistentdomain
        ://this-is-a-non-existent-domain.nonexistentdomain
        this-is-a-non-existent-domain.nonexistentdomain
        http://:this-is-a-non-existent-domain.nonexistentdomain
        carrot://foo:80this-is-a-non-existent-domain.nonexistentdomain
      ] do
        assert {:error, error} = HTTP.request(:get, url)

        assert error.message =~
                 ~r/invalid scheme|the :hostname option is required when address is not a binary/
      end
    end

    test "when domain does not exist" do
      assert {:error, error} = HTTP.request(:get, "http://dangcom.carrotinsta/")
      assert error.reason == :nxdomain
    end

    test "when server refuses connections" do
      assert {:error, error} = HTTP.request(:get, "http://localhost:4082/")
      assert error.reason == :econnrefused
    end
  end

  describe "timeouts" do
    test "when we timeout connecting" do
      assert {elapsed_us, {:error, error}} =
               :timer.tc(fn -> HTTP.request(:get, "http://google.com:4082/") end)

      assert error.reason == :timeout
      # connect timeout is 100 ms
      assert round(elapsed_us / 1000) in 100..200
    end

    test "when we timeout reading" do
      assert {:error, error} = HTTP.request(:get, test_url("sleep/200"), [], nil, 200)
      assert error.reason == :timeout
    end

    # This is currently failing
    @tag :skip
    test "when pool times out" do
      test_pid = self()
      iters = 1..60

      Enum.each(iters, fn i ->
        spawn(fn ->
          send(test_pid, {:done, i})
          assert {:ok, _resp} = HTTP.request(:get, test_url("sleep/200"), [], nil, 300)
        end)
      end)

      Enum.each(iters, fn i ->
        receive do
          {:done, ^i} -> :ok
        after
          10_000 -> raise "Shouldn't happen"
        end
      end)

      assert {:error, _error} = HTTP.request(:get, test_url("/"))
    end
  end

  describe "valid status codes" do
    for status <-
          Enum.concat([
            200..208,
            300..308,
            400..418,
            422..426,
            428..429,
            [431],
            500..508
          ]) do
      @status status
      test "when status code is #{@status}" do
        status = @status
        url = test_url("/status/#{status}")

        body = MockServer.content_for(to_string(status))

        assert {:ok, resp} = HTTP.request(:get, url)
        assert resp.body == body
        assert resp.status == status
      end
    end
  end

  describe "large response" do
    test "returns body" do
      assert {:ok, resp} = HTTP.request(:get, test_url("large-response"))
      assert String.length(resp.body) == 1000_000
    end
  end

  describe "edge cases" do
    @tag :skip
    test "when response is smaller than content-length"
    @tag :skip
    test "when response is larger than content-length"
  end

  describe "retry" do
    test "retries 3 times for 500" do
      ref = :erlang.unique_integer([:positive])
      assert {:ok, resp} = HTTP.request(%Request{url: test_url("refs/#{ref}/500")})
      assert resp.status == 500
      assert 4 == MockServer.count_for(ref)
    end

    test "retries 1 time when configured for 1 retry" do
      ref = :erlang.unique_integer([:positive])
      assert {:ok, resp} = HTTP.request(%Request{retry: 1, url: test_url("refs/#{ref}/501")})
      assert resp.status == 501
      assert 2 == MockServer.count_for(ref)
    end
  end
end
