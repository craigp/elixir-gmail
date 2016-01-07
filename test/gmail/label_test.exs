ExUnit.start

defmodule Gmail.LabelTest do

  use ExUnit.Case
  import Mock

  setup do

    access_token = "xxx-xxx-xxx"
    access_token_rec = %{access_token: access_token}

    label_id = "Label_22"
    label_name = "Cool Label"
    label_type = "user"

    label = %{
      "id" => label_id,
      "name" => label_name,
      "type" => label_type,
      "labelListVisibility" => "labelShow",
      "messageListVisibility" => "show"
    }

    labels = %{"labels" => [label]}

    expected_result = %Gmail.Label{
      id: label_id,
      name: label_name,
      type: label_type,
      labelListVisibility: "labelShow",
      messageListVisibility: "show"
    }

    expected_results = [expected_result]

    errors = [
      %{"message" => "Error #1"},
      %{"message" => "Error #2"}
    ]

    error_content = %{"code" => 400, "errors" => errors}

    {:ok, %{
        access_token: access_token,
        access_token_rec: access_token_rec,
        label_id: label_id,
        label_name: label_name,
        label: label,
        labels: labels,
        expected_result: expected_result,
        expected_results: expected_results,
        label_not_found: %{"error" => %{"code" => 404}},
        four_hundred_error: %{"error" => error_content},
        four_hundred_error_content: error_content
      }}
  end

  test "creates a new label", context do
    with_mock Gmail.HTTP, [post: fn _at, _url, _data -> {:ok, context[:label]} end] do
      with_mock Gmail.OAuth2, [get_config: fn -> context[:access_token_rec] end] do
        {:ok, label} = Gmail.Label.create(context[:label_name])
        assert context[:expected_result] == label
        assert called Gmail.OAuth2.get_config
        assert called Gmail.HTTP.post(context[:access_token],
          Gmail.Base.base_url <> "users/me/labels", %{"name" => context[:label_name]})
      end
    end
  end

  test "deletes a label", context do
    with_mock Gmail.HTTP, [delete: fn _at, _url -> {:ok, nil} end] do
      with_mock Gmail.OAuth2, [get_config: fn -> context[:access_token_rec] end] do
        :ok = Gmail.Label.delete(context[:label_id])
        assert called Gmail.OAuth2.get_config
        assert called Gmail.HTTP.delete(context[:access_token],
          Gmail.Base.base_url <> "users/me/labels/" <> context[:label_id])
      end
    end
  end

  test "reports a :not_found when deleting a label that doesn't exist", context do
    with_mock Gmail.HTTP, [delete: fn _at, _url -> {:ok, context[:label_not_found]} end] do
      with_mock Gmail.OAuth2, [get_config: fn -> context[:access_token_rec] end] do
        :not_found = Gmail.Label.delete(context[:label_id])
        assert called Gmail.OAuth2.get_config
        assert called Gmail.HTTP.delete(context[:access_token],
          Gmail.Base.base_url <> "users/me/labels/" <> context[:label_id])
      end
    end
  end

  test "handles a 400 error when deleting a label", context do
    with_mock Gmail.HTTP, [delete: fn _at, _url -> {:ok, context[:four_hundred_error]} end] do
      with_mock Gmail.OAuth2, [get_config: fn -> context[:access_token_rec] end] do
        {:error, "Error #1"} = Gmail.Label.delete(context[:label_id])
        assert called Gmail.OAuth2.get_config
        assert called Gmail.HTTP.delete(context[:access_token],
          Gmail.Base.base_url <> "users/me/labels/" <> context[:label_id])
      end
    end
  end

  test "lists all labels", context do
    with_mock Gmail.HTTP, [get: fn _at, _url -> {:ok, context[:labels]} end] do
      with_mock Gmail.OAuth2, [get_config: fn -> context[:access_token_rec] end] do
        {:ok, labels} = Gmail.Label.list
        assert context[:expected_results] == labels
        assert called Gmail.OAuth2.get_config
        assert called Gmail.HTTP.get(context[:access_token],
          Gmail.Base.base_url <> "users/me/labels")
      end
    end
  end

  test "updates a label", context do
    with_mock Gmail.HTTP, [put: fn _at, _url, _data -> {:ok, context[:label]} end] do
      with_mock Gmail.OAuth2, [get_config: fn -> context[:access_token_rec] end] do
        {:ok, label} = Gmail.Label.update(context[:expected_result])
        assert context[:expected_result] == label
        assert called Gmail.OAuth2.get_config
        assert called Gmail.HTTP.put(context[:access_token],
          Gmail.Base.base_url <> "users/me/labels/" <> context[:label_id],
          %{
            "id" => context[:label_id],
            "name" => context[:label_name],
            "labelListVisibility" => "labelShow",
            "messageListVisibility" => "show"
          })
      end
    end
  end

  test "handles an error when updating a label", context do
    with_mock Gmail.HTTP, [put: fn _at, _url, _data -> {:ok, context[:four_hundred_error]} end] do
      with_mock Gmail.OAuth2, [get_config: fn -> context[:access_token_rec] end] do
        # {:error, context[:four_hundred_error_content]} = Gmail.Label.update(context[:expected_result])
        {:error, error_detail} = Gmail.Label.update(context[:expected_result])
        assert context[:four_hundred_error_content] == error_detail
        assert called Gmail.OAuth2.get_config
        assert called Gmail.HTTP.put(context[:access_token],
          Gmail.Base.base_url <> "users/me/labels/" <> context[:label_id],
          %{
            "id" => context[:label_id],
            "name" => context[:label_name],
            "labelListVisibility" => "labelShow",
            "messageListVisibility" => "show"
          })
      end
    end
  end

  test "gets a label", context do
    with_mock Gmail.HTTP, [get: fn _at, _url -> {:ok, context[:label]} end] do
      with_mock Gmail.OAuth2, [get_config: fn -> context[:access_token_rec] end] do
        {:ok, label} = Gmail.Label.get(context[:label_id])
        assert context[:expected_result] == label
        assert called Gmail.OAuth2.get_config
        assert called Gmail.HTTP.get(context[:access_token],
          Gmail.Base.base_url <> "users/me/labels/" <> context[:label_id])
      end
    end
  end

  test "reports :not_found for a label that doesn't exist", context do
    with_mock Gmail.HTTP, [get: fn _at, _url -> {:ok, context[:label_not_found]} end] do
      with_mock Gmail.OAuth2, [get_config: fn -> context[:access_token_rec] end] do
        {:error, :not_found} = Gmail.Label.get(context[:label_id])
        assert called Gmail.OAuth2.get_config
        assert called Gmail.HTTP.get(context[:access_token],
          Gmail.Base.base_url <> "users/me/labels/" <> context[:label_id])
      end
    end
  end

  test "handles a 400 error when getting a label", context do
    with_mock Gmail.HTTP, [get: fn _at, _url -> {:ok, context[:four_hundred_error]} end] do
      with_mock Gmail.OAuth2, [get_config: fn -> context[:access_token_rec] end] do
        {:error, "Error #1"} = Gmail.Label.get(context[:label_id])
        assert called Gmail.OAuth2.get_config
        assert called Gmail.HTTP.get(context[:access_token],
          Gmail.Base.base_url <> "users/me/labels/" <> context[:label_id])
      end
    end
  end

  # test "patches a label" do

  # end

end
