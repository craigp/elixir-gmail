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
    user_id = "user@example.com"

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
      label_list_visibility: "labelShow",
      message_list_visibility: "show"
    }

    expected_results = [expected_result]

    error_message_1 = "Error #1"
    errors = [
      %{"message" => error_message_1},
      %{"message" => "Error #2"}
    ]

    error_content = %{"code" => 400, "errors" => errors}

    bypass = Bypass.open
    Application.put_env :gmail, :api, %{url: "http://localhost:#{bypass.port}/gmail/v1/"}

    Gmail.User.stop_mail(user_id)
    with_mock Gmail.OAuth2, [refresh_access_token: fn(_) -> {:ok, {access_token, 100000000000000}} end] do
      {:ok, _server_pid} = Gmail.User.start_mail(user_id, "dummy-refresh-token")
    end

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
        four_hundred_error_content: error_content,
        bypass: bypass,
        user_id: user_id,
        error_message_1: error_message_1
      }}
  end

  test "creates a new label", %{
    label: label,
    label_name: label_name,
    expected_result: expected_result,
    bypass: bypass,
    access_token: access_token,
    user_id: user_id
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/labels" == conn.request_path
      assert "" == conn.query_string
      assert "POST" == conn.method
      assert {"authorization", "Bearer #{access_token}"} in conn.req_headers
      {:ok, json} = Poison.encode(label)
      Plug.Conn.resp(conn, 200, json)
    end
    {:ok, label} = Gmail.User.label(:create, user_id, label_name)
    assert expected_result == label
  end

  test "deletes a label", %{
    bypass: bypass,
    label_id: label_id,
    user_id: user_id
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/labels/#{label_id}" == conn.request_path
      assert "" == conn.query_string
      assert "DELETE" == conn.method
      {:ok, json} = Poison.encode(nil)
      Plug.Conn.resp(conn, 200, json)
    end
    :ok = Gmail.User.label(:delete, user_id, label_id)
  end

  test "reports a :not_found when deleting a label that doesn't exist", %{
    bypass: bypass,
    label_not_found: label_not_found,
    label_id: label_id,
    user_id: user_id
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/labels/#{label_id}" == conn.request_path
      assert "" == conn.query_string
      {:ok, json} = Poison.encode(label_not_found)
      Plug.Conn.resp(conn, 200, json)
    end
    {:error, :not_found} = Gmail.User.label(:delete, user_id, label_id)
  end

  test "handles a 400 error when deleting a label", %{
    bypass: bypass,
    label_id: label_id,
    four_hundred_error: four_hundred_error,
    user_id: user_id
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/labels/#{label_id}" == conn.request_path
      assert "" == conn.query_string
      {:ok, json} = Poison.encode(four_hundred_error)
      Plug.Conn.resp(conn, 200, json)
    end
    {:error, "Error #1"} = Gmail.User.label(:delete, user_id, label_id)
  end

  test "lists all labels", %{
    labels: labels,
    expected_results: expected_results,
    bypass: bypass,
    user_id: user_id
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/labels" == conn.request_path
      assert "" == conn.query_string
      assert "GET" == conn.method
      {:ok, json} = Poison.encode(labels)
      Plug.Conn.resp(conn, 200, json)
    end
    {:ok, labels} = Gmail.User.labels(user_id)
    assert expected_results == labels
  end

  test "updates a label", %{
    label: label,
    label_name: label_name,
    expected_result: expected_result,
    bypass: bypass,
    label_id: label_id,
    user_id: user_id
  } do
    Bypass.expect bypass, fn conn ->
      {:ok, body, _} = Plug.Conn.read_body(conn)
      {:ok, body_params} = body |> Poison.decode
      assert body_params == %{
        "id" => label_id,
        "name" => label_name,
        "labelListVisibility" => "labelShow",
        "messageListVisibility" => "show"
      }
      assert "/gmail/v1/users/#{user_id}/labels/#{label_id}" == conn.request_path
      assert "" == conn.query_string
      assert "PUT" == conn.method
      {:ok, json} = Poison.encode(label)
      Plug.Conn.resp(conn, 200, json)
    end
    {:ok, label} = Gmail.User.label(:update, user_id, expected_result)
    assert expected_result == label
  end

  test "handles an error when updating a label", %{
    expected_result: expected_result,
    bypass: bypass,
    label_id: label_id,
    four_hundred_error: four_hundred_error,
    user_id: user_id,
    error_message_1: error_message_1
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/labels/#{label_id}" == conn.request_path
      assert "" == conn.query_string
      {:ok, json} = Poison.encode(four_hundred_error)
      Plug.Conn.resp(conn, 200, json)
    end
    {:error, error_detail} = Gmail.User.label(:update, user_id, expected_result)
    assert error_message_1 == error_detail
  end

  test "gets a label", %{
    label: label,
    expected_result: expected_result,
    bypass: bypass,
    label_id: label_id,
    user_id: user_id
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/labels/#{label_id}" == conn.request_path
      assert "" == conn.query_string
      assert "GET" == conn.method
      {:ok, json} = Poison.encode(label)
      Plug.Conn.resp(conn, 200, json)
    end
    {:ok, label} = Gmail.User.label(user_id, label_id)
    assert expected_result == label
  end

  test "reports :not_found for a label that doesn't exist", %{
    bypass: bypass,
    label_not_found: label_not_found,
    label_id: label_id,
    user_id: user_id
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/labels/#{label_id}" == conn.request_path
      assert "" == conn.query_string
      {:ok, json} = Poison.encode(label_not_found)
      Plug.Conn.resp(conn, 200, json)
    end
    {:error, :not_found} = Gmail.User.label(user_id, label_id)
  end

  test "handles a 400 error when getting a label", %{
    bypass: bypass,
    four_hundred_error: four_hundred_error,
    label_id: label_id,
    user_id: user_id
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/labels/#{label_id}" == conn.request_path
      assert "" == conn.query_string
      {:ok, json} = Poison.encode(four_hundred_error)
      Plug.Conn.resp(conn, 200, json)
    end
    {:error, "Error #1"} = Gmail.User.label(user_id, label_id)
  end

  test "patches a label", %{
    label: label,
    label_name: label_name,
    expected_result: expected_result,
    bypass: bypass,
    label_name: label_name,
    label_id: label_id,
    expected_result: expected_result,
    user_id: user_id
  } do
    new_label_name = "Something Else"
    patched_label = %{label | "name" => new_label_name}
    expected_result = %{expected_result | name: new_label_name}
    patch_label = %Gmail.Label{id: label_id, name: new_label_name}
    Bypass.expect bypass, fn conn ->
      {:ok, body, _} = Plug.Conn.read_body(conn)
      {:ok, body_params} = body |> Poison.decode
      assert body_params == %{
        "id" => label_id,
        "name" => new_label_name
      }
      assert "/gmail/v1/users/#{user_id}/labels/#{label_id}" == conn.request_path
      assert "" == conn.query_string
      assert "PATCH" == conn.method
      {:ok, json} = Poison.encode(patched_label)
      Plug.Conn.resp(conn, 200, json)
    end
    {:ok, label} = Gmail.User.label(:patch, user_id, patch_label)
    assert expected_result == label
  end

  test "handles an error when patching a label", %{
    bypass: bypass,
    four_hundred_error: four_hundred_error,
    label_id: label_id,
    user_id: user_id,
    error_message_1: error_message_1
  } do
    new_label_name = "Something Else"
    patch_label = %Gmail.Label{id: label_id, name: new_label_name}
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/#{user_id}/labels/#{label_id}" == conn.request_path
      assert "" == conn.query_string
      {:ok, json} = Poison.encode(four_hundred_error)
      Plug.Conn.resp(conn, 200, json)
    end
    {:error, error_detail} = Gmail.User.label(:patch, user_id, patch_label)
    assert error_message_1 == error_detail
  end

end
