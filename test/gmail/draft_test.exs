ExUnit.start

defmodule Gmail.DraftTest do

  use ExUnit.Case
  import Mock

  setup do

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
        send_response: %{"id" => "1530e43ba9b4c6e0", "labelIds" => ["SENT"], "threadId" => "14c99e3025c516a0"}
      }}
  end

  test "sends a draft", %{
    draft_id: draft_id,
    bypass: bypass,
    access_token_rec: access_token_rec,
    access_token: access_token,
    send_response: send_response
  } do
    data = %{"id" => draft_id}
    Bypass.expect bypass, fn conn ->
      {:ok, body, _} = Plug.Conn.read_body(conn)
      {:ok, body_params} = body |> Poison.decode
      assert body_params == data
      assert "/gmail/v1/users/me/drafts/send" == conn.request_path
      assert "" == conn.query_string
      assert "POST" == conn.method
      assert {"authorization", "Bearer #{access_token}"} in conn.req_headers
      {:ok, json} = Poison.encode(send_response)
      Plug.Conn.resp(conn, 200, json)
    end
    with_mock Gmail.OAuth2, [get_config: fn -> access_token_rec end] do
      {:ok, %{thread_id: _thread_id}} = Gmail.Draft.send(draft_id)
      assert called Gmail.OAuth2.get_config
    end
  end

  test "reports a :not_found when sending a draft that doesn't exist", %{
    draft_id: draft_id,
    bypass: bypass,
    access_token_rec: access_token_rec,
    access_token: access_token,
    draft_not_found: draft_not_found
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/me/drafts/send" == conn.request_path
      assert "" == conn.query_string
      assert "POST" == conn.method
      assert {"authorization", "Bearer #{access_token}"} in conn.req_headers
      {:ok, json} = Poison.encode(draft_not_found)
      Plug.Conn.resp(conn, 200, json)
    end
    with_mock Gmail.OAuth2, [get_config: fn -> access_token_rec end] do
      {:error, :not_found} = Gmail.Draft.send(draft_id)
      assert called Gmail.OAuth2.get_config
    end
  end

  # test "creates a new draft" do
  # end

  test "deletes a draft", %{
    draft_id: draft_id,
    access_token_rec: access_token_rec,
    bypass: bypass
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/me/drafts/#{draft_id}" == conn.request_path
      assert "" == conn.query_string
      assert "DELETE" == conn.method
      Plug.Conn.resp(conn, 200, "")
    end
    with_mock Gmail.OAuth2, [ get_config: fn -> access_token_rec end ] do
      assert :ok == Gmail.Draft.delete(draft_id)
      assert called Gmail.OAuth2.get_config
    end
  end

  test "reports :not_found when deleting a draft that doesn't exist", %{
    draft_id: draft_id,
    access_token_rec: access_token_rec,
    bypass: bypass,
    draft_not_found: draft_not_found
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/me/drafts/#{draft_id}" == conn.request_path
      assert "" == conn.query_string
      assert "DELETE" == conn.method
      {:ok, json} = Poison.encode(draft_not_found)
      Plug.Conn.resp(conn, 200, json)
    end
    with_mock Gmail.OAuth2, [ get_config: fn -> access_token_rec end ] do
      {:error, :not_found} = Gmail.Draft.delete(draft_id)
      assert called Gmail.OAuth2.get_config
    end
  end

  test "lists all drafts", %{
    drafts: drafts,
    access_token_rec: access_token_rec,
    expected_results: expected_results,
    access_token: access_token,
    bypass: bypass
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/me/drafts" == conn.request_path
      assert "" == conn.query_string
      assert {"authorization", "Bearer #{access_token}"} in conn.req_headers
      assert "GET" == conn.method
      {:ok, json} = Poison.encode(drafts)
      Plug.Conn.resp(conn, 200, json)
    end
    with_mock Gmail.OAuth2, [ get_config: fn -> access_token_rec end ] do
      {:ok, results} = Gmail.Draft.list
      assert results == expected_results
      assert called Gmail.OAuth2.get_config
    end
  end

  # test "updates a draft" do

  # end

  test "gets a draft", %{
    draft: draft,
    draft_id: draft_id,
    access_token_rec: access_token_rec,
    expected_result: expected_result,
    bypass: bypass
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/me/drafts/#{draft_id}" == conn.request_path
      assert "format=full" == conn.query_string
      {:ok, json} = Poison.encode(draft)
      Plug.Conn.resp(conn, 200, json)
    end
    with_mock Gmail.OAuth2, [ get_config: fn -> access_token_rec end ] do
      {:ok, draft} = Gmail.Draft.get(draft_id)
      assert draft == expected_result
      assert called Gmail.OAuth2.get_config
    end
  end

  test "reports :not_found for a draft that doesn't exist", %{
    draft_id: draft_id,
    access_token_rec: access_token_rec,
    bypass: bypass,
    draft_not_found: draft_not_found
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/me/drafts/#{draft_id}" == conn.request_path
      assert "format=full" == conn.query_string
      {:ok, json} = Poison.encode(draft_not_found)
      Plug.Conn.resp(conn, 200, json)
    end
    with_mock Gmail.OAuth2, [ get_config: fn -> access_token_rec end ] do
      {:error, :not_found} = Gmail.Draft.get(draft_id)
      assert called Gmail.OAuth2.get_config
    end
  end

end

