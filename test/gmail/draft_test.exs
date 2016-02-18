ExUnit.start

defmodule Gmail.DraftTest do

  use ExUnit.Case
  import Mock

  setup do

    access_token = "xxx-xxx-xxx"
    access_token_rec = %{access_token: access_token}

    drafts = %{"drafts" => [%{"id" => "1497963903688490569",
        "message" => %{"id" => "14c9d65152e73310",
          "threadId" => "14c99e3025c516a0"}},
      %{"id" => "1492564013423058235",
        "message" => %{"id" => "14b6a70ff09cdd3b",
          "threadId" => "14b643d16976ad29"}},
      %{"id" => "1478425285387648346",
        "message" => %{"id" => "14846bf6ca7c7d5a",
          "threadId" => "14844b4410da5151"}}]}

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
        access_token: access_token,
        access_token_rec: access_token_rec,
        drafts: drafts,
        expected_results: expected_results,
        bypass: bypass
      }}
  end

  # test "creates a new draft" do
  # end

  # test "deletes a draft" do

  # end

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

  # test "gets a draft", context do

  # end

end

