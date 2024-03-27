defmodule BlockScoutWeb.API.V2.ConfigControllerTest do
  use BlockScoutWeb.ConnCase

  describe "/config/json-rpc-url" do

    test "get json rpc url if set", %{conn: conn} do
      url = "http://rpc.url:1234/v1"
      Application.put_env(:block_scout_web, :json_rpc_url, url)

      request = get(conn, "/api/v2/config/json-rpc-url")

      assert %{"json_rpc_url" => ^url} = json_response(request, 200)
    end

    test "get empty json rpc url if not set", %{conn: conn} do
      Application.put_env(:block_scout_web, :json_rpc_url, nil)

      request = get(conn, "/api/v2/config/json-rpc-url")

      assert %{"json_rpc_url" => nil} = json_response(request, 200)
    end

  end

  describe "/config/backend-version" do

    test "get backend version if set", %{conn: conn} do
      backend_version = "1.0.0"
      Application.put_env(:block_scout_web, :backend_version, backend_version)

      request = get(conn, "/api/v2/config/backend-version")

      assert %{"backend_version" => ^backend_version} = json_response(request, 200)
    end

    test "get empty backend version if not set", %{conn: conn} do
      Application.put_env(:block_scout_web, :backend_version, nil)

      request = get(conn, "/api/v2/config/backend-version")

      assert %{"backend_version" => nil} = json_response(request, 200)
    end

  end

end
