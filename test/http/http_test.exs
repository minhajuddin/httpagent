defmodule HA.HTTPTest do
  use HA.DataCase

  alias HA.HTTP

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
      assert {:error, error} = HTTP.request(:get, "http://google.com:4082/")
      assert error == "test"
    end
  end
end
