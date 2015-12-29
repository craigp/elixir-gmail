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

    {:ok, %{
        access_token: access_token,
        access_token_rec: access_token_rec,
        drafts: drafts,
        expected_results: expected_results
      }}
  end

  # test "creates a new draft" do
  # end

  # test "deletes a draft" do

  # end

  test "lists all drafts", context do
    with_mock Gmail.HTTP, [ get: fn _at, _url -> { :ok, context[:drafts] } end] do
      with_mock Gmail.OAuth2, [ get_config: fn -> context[:access_token_rec] end ] do
        {:ok, results} = Gmail.Draft.list
        assert results == context[:expected_results]
        assert called Gmail.OAuth2.get_config
        assert called Gmail.HTTP.get(context[:access_token], Gmail.Base.base_url <> "users/me/drafts")
      end
    end
  end

  # test "updates a draft" do

  # end

  # test "gets a draft", context do

  # end

end

