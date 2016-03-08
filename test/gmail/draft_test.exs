ExUnit.start

defmodule Gmail.DraftTest do

  use ExUnit.Case
  import Mock

  setup do

    user_id = "user@example.com"
    access_token = "xxx-xxx-xxx"
    access_token_rec = %{access_token: access_token}

    draft_id = "1497963903688490569"

    draft = %{"id" => "1497963903688490569",
      "message" => %{"id" => "14c9d65152e73310",
        "threadId" => "14c99e3025c516a0"}}

    drafts = %{"drafts" => [%{"id" => "1497963903688490569",
        "message" => %{"id" => "14c9d65152e73310",
          "threadId" => "14c99e3025c516a0"}},
      %{"id" => "1492564013423058235",
        "message" => %{"id" => "14b6a70ff09cdd3b",
          "threadId" => "14b643d16976ad29"}},
      %{"id" => "1478425285387648346",
        "message" => %{"id" => "14846bf6ca7c7d5a",
          "threadId" => "14844b4410da5151"}}]}

    expected_result = %Gmail.Draft{
      id: draft_id,
      message: %Gmail.Message{
        id: "14c9d65152e73310",
        thread_id: "14c99e3025c516a0"
      }
    }

    expected_results = [%Gmail.Draft{
        id: "1497963903688490569",
        message: %Gmail.Message{
          id: "14c9d65152e73310",
          thread_id: "14c99e3025c516a0"
        }
      }, %Gmail.Draft{
        id: "1492564013423058235",
        message: %Gmail.Message{
          id: "14b6a70ff09cdd3b",
          thread_id: "14b643d16976ad29"
        }
      }, %Gmail.Draft{
        id: "1478425285387648346",
        message: %Gmail.Message{
          id: "14846bf6ca7c7d5a",
          thread_id: "14844b4410da5151"
        }
      }]

    bypass = Bypass.open
    Application.put_env :gmail, :api, %{url: "http://localhost:#{bypass.port}/gmail/v1/"}

    with_mock Gmail.OAuth2, [refresh_access_token: fn(_) -> {access_token, 100000000000000} end] do
      {:ok, _server_pid} = Gmail.User.start_mail(user_id, "dummy-refresh-token")
    end

    {:ok, %{
        draft_id: draft_id,
        draft: draft,
        expected_result: expected_result,
        access_token: access_token,
        access_token_rec: access_token_rec,
        drafts: drafts,
        expected_results: expected_results,
        draft_not_found: %{"error" => %{"code" => 404}},
        bypass: bypass,
        send_response: %{"id" => "1530e43ba9b4c6e0", "labelIds" => ["SENT"], "threadId" => "14c99e3025c516a0"},
        user_id: user_id
      }}
  end

  test "sends a draft", %{
    draft_id: draft_id,
    bypass: bypass,
    access_token: access_token,
    send_response: send_response,
    user_id: user_id
  } do
    data = %{"id" => draft_id}
    Bypass.expect bypass, fn conn ->
      {:ok, body, _} = Plug.Conn.read_body(conn)
      {:ok, body_params} = body |> Poison.decode
      assert body_params == data
      assert "/gmail/v1/users/#{user_id}/drafts/send" == conn.request_path
      assert "" == conn.query_string
      assert "POST" == conn.method
      assert {"authorization", "Bearer #{access_token}"} in conn.req_headers
      {:ok, json} = Poison.encode(send_response)
      Plug.Conn.resp(conn, 200, json)
    end
    {:ok, %{thread_id: _thread_id}} = Gmail.User.draft(:send, user_id, draft_id)
  end

  test "reports a :not_found when sending a draft that doesn't exist", %{
    draft_id: draft_id,
    bypass: bypass,
    access_token: access_token,
    draft_not_found: draft_not_found,
    user_id: user_id
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/drafts/send" == conn.request_path
      assert "" == conn.query_string
      assert "POST" == conn.method
      assert {"authorization", "Bearer #{access_token}"} in conn.req_headers
      {:ok, json} = Poison.encode(draft_not_found)
      Plug.Conn.resp(conn, 200, json)
    end
    {:error, :not_found} = Gmail.User.draft(:send, user_id, draft_id)
  end

  # test "creates a new draft" do
  # end

  test "deletes a draft", %{
    draft_id: draft_id,
    bypass: bypass,
    user_id: user_id
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/drafts/#{draft_id}" == conn.request_path
      assert "" == conn.query_string
      assert "DELETE" == conn.method
      Plug.Conn.resp(conn, 200, "")
    end
    assert :ok == Gmail.User.draft(:delete, user_id, draft_id)
  end

  test "reports :not_found when deleting a draft that doesn't exist", %{
    draft_id: draft_id,
    bypass: bypass,
    draft_not_found: draft_not_found,
    user_id: user_id
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/drafts/#{draft_id}" == conn.request_path
      assert "" == conn.query_string
      assert "DELETE" == conn.method
      {:ok, json} = Poison.encode(draft_not_found)
      Plug.Conn.resp(conn, 200, json)
    end
    {:error, :not_found} = Gmail.User.draft(:delete, user_id, draft_id)
  end

  test "lists all drafts", %{
    drafts: drafts,
    expected_results: expected_results,
    access_token: access_token,
    bypass: bypass,
    user_id: user_id
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/drafts" == conn.request_path
      assert "" == conn.query_string
      assert {"authorization", "Bearer #{access_token}"} in conn.req_headers
      assert "GET" == conn.method
      {:ok, json} = Poison.encode(drafts)
      Plug.Conn.resp(conn, 200, json)
    end
    {:ok, results} = Gmail.User.drafts(user_id)
    assert results == expected_results
  end

  # test "updates a draft" do

  # end

  test "gets a draft", %{
    draft: draft,
    draft_id: draft_id,
    expected_result: expected_result,
    bypass: bypass,
    user_id: user_id
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/drafts/#{draft_id}" == conn.request_path
      assert "" == conn.query_string
      {:ok, json} = Poison.encode(draft)
      Plug.Conn.resp(conn, 200, json)
    end
    {:ok, draft} = Gmail.User.draft(user_id, draft_id)
    assert draft == expected_result
  end

  test "reports :not_found for a draft that doesn't exist", %{
    draft_id: draft_id,
    bypass: bypass,
    draft_not_found: draft_not_found,
    user_id: user_id
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/drafts/#{draft_id}" == conn.request_path
      assert "" == conn.query_string
      {:ok, json} = Poison.encode(draft_not_found)
      Plug.Conn.resp(conn, 200, json)
    end
    {:error, :not_found} = Gmail.User.draft(user_id, draft_id)
  end

end

