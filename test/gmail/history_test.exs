ExUnit.start

defmodule Gmail.HistoryTest do

  use ExUnit.Case
  import Mock

  setup do
    user_id = "user@example.com"
    access_token = "xxx-xxx-xxx"
    history = %{"history" => [
        %{"historyId" => 12345},
        %{"historyId" => 12346},
      ]}
    bypass = Bypass.open
    Application.put_env :gmail, :api, %{url: "http://localhost:#{bypass.port}/gmail/v1/"}
    Gmail.User.stop_mail(user_id)
    with_mock Gmail.OAuth2, [refresh_access_token: fn(_) -> {access_token, 100000000000000} end] do
      {:ok, _server_pid} = Gmail.User.start_mail(user_id, "dummy-refresh-token")
    end
    {:ok,
      access_token: access_token,
      user_id: user_id,
      bypass: bypass,
      history: history
    }
  end

  test "gets a list of history items", %{
    bypass: bypass,
    user_id: user_id,
    access_token: access_token,
    history: %{"history" => history_items} = history
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/history" == conn.request_path
      assert "" == conn.query_string
      assert "GET" == conn.method
      assert {"authorization", "Bearer #{access_token}"} in conn.req_headers
      {:ok, json} = Poison.encode(history)
      Plug.Conn.resp(conn, 200, json)
    end
    {:ok, user_history} = Gmail.User.history(user_id)
    assert user_history == Gmail.Helper.atomise_keys(history_items)
  end

  test "gets a list of history items with a max number of results", %{
    bypass: bypass,
    user_id: user_id,
    access_token: access_token,
    history: %{"history" => history_items} = history
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/history" == conn.request_path
      assert URI.encode_query(%{"maxResults" => 20}) == conn.query_string
      assert "GET" == conn.method
      assert {"authorization", "Bearer #{access_token}"} in conn.req_headers
      {:ok, json} = Poison.encode(history)
      Plug.Conn.resp(conn, 200, json)
    end
    {:ok, user_history} = Gmail.User.history(user_id, %{max_results: 20})
    assert user_history == Gmail.Helper.atomise_keys(history_items)
  end

end
