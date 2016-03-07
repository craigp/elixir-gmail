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

    errors = [
      %{"message" => "Error #1"},
      %{"message" => "Error #2"}
    ]

    error_content = %{"code" => 400, "errors" => errors}

    bypass = Bypass.open
    Application.put_env :gmail, :api, %{url: "http://localhost:#{bypass.port}/gmail/v1/"}

    with_mock Gmail.OAuth2, [refresh_access_token: fn(_) -> {access_token, 100000000000000} end] do
      {:ok, _server_pid} = Gmail.User.start(user_id, "dummy-refresh-token")
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
        user_id: user_id
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
    access_token_rec: access_token_rec,
    bypass: bypass,
    label_id: label_id
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/me/labels/#{label_id}" == conn.request_path
      assert "" == conn.query_string
      assert "DELETE" == conn.method
      {:ok, json} = Poison.encode(nil)
      Plug.Conn.resp(conn, 200, json)
    end
    with_mock Gmail.OAuth2, [get_config: fn -> access_token_rec end] do
      :ok = Gmail.Label.delete(label_id)
      assert called Gmail.OAuth2.get_config
    end
  end

  test "reports a :not_found when deleting a label that doesn't exist", %{
    access_token_rec: access_token_rec,
    bypass: bypass,
    label_not_found: label_not_found,
    label_id: label_id
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/me/labels/#{label_id}" == conn.request_path
      assert "" == conn.query_string
      {:ok, json} = Poison.encode(label_not_found)
      Plug.Conn.resp(conn, 200, json)
    end
    with_mock Gmail.OAuth2, [get_config: fn -> access_token_rec end] do
      :not_found = Gmail.Label.delete(label_id)
      assert called Gmail.OAuth2.get_config
    end
  end

  test "handles a 400 error when deleting a label", %{
    access_token_rec: access_token_rec,
    bypass: bypass,
    label_id: label_id,
    four_hundred_error: four_hundred_error
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/me/labels/#{label_id}" == conn.request_path
      assert "" == conn.query_string
      {:ok, json} = Poison.encode(four_hundred_error)
      Plug.Conn.resp(conn, 200, json)
    end
    with_mock Gmail.OAuth2, [get_config: fn -> access_token_rec end] do
      {:error, "Error #1"} = Gmail.Label.delete(label_id)
      assert called Gmail.OAuth2.get_config
    end
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
    access_token_rec: access_token_rec,
    expected_result: expected_result,
    bypass: bypass,
    label_id: label_id
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
      assert "/gmail/v1/users/me/labels/#{label_id}" == conn.request_path
      assert "" == conn.query_string
      assert "PUT" == conn.method
      {:ok, json} = Poison.encode(label)
      Plug.Conn.resp(conn, 200, json)
    end
    with_mock Gmail.OAuth2, [get_config: fn -> access_token_rec end] do
      {:ok, label} = Gmail.Label.update(expected_result)
      assert expected_result == label
      assert called Gmail.OAuth2.get_config
    end
  end

  test "handles an error when updating a label", %{
    access_token_rec: access_token_rec,
    expected_result: expected_result,
    bypass: bypass,
    label_id: label_id,
    four_hundred_error: four_hundred_error,
    four_hundred_error_content: four_hundred_error_content
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/me/labels/#{label_id}" == conn.request_path
      assert "" == conn.query_string
      {:ok, json} = Poison.encode(four_hundred_error)
      Plug.Conn.resp(conn, 200, json)
    end
    with_mock Gmail.OAuth2, [get_config: fn -> access_token_rec end] do
      {:error, error_detail} = Gmail.Label.update(expected_result)
      assert four_hundred_error_content == error_detail
      assert called Gmail.OAuth2.get_config
    end
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
    access_token_rec: access_token_rec,
    bypass: bypass,
    label_not_found: label_not_found,
    label_id: label_id
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/me/labels/#{label_id}" == conn.request_path
      assert "" == conn.query_string
      {:ok, json} = Poison.encode(label_not_found)
      Plug.Conn.resp(conn, 200, json)
    end
    with_mock Gmail.OAuth2, [get_config: fn -> access_token_rec end] do
      {:error, :not_found} = Gmail.Label.get(label_id)
      assert called Gmail.OAuth2.get_config
    end
  end

  test "handles a 400 error when getting a label", %{
    access_token_rec: access_token_rec,
    bypass: bypass,
    four_hundred_error: four_hundred_error,
    label_id: label_id
  } do
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/me/labels/#{label_id}" == conn.request_path
      assert "" == conn.query_string
      {:ok, json} = Poison.encode(four_hundred_error)
      Plug.Conn.resp(conn, 200, json)
    end
    with_mock Gmail.OAuth2, [get_config: fn -> access_token_rec end] do
      {:error, "Error #1"} = Gmail.Label.get(label_id)
      assert called Gmail.OAuth2.get_config
    end
  end

  test "patches a label", %{
    label: label,
    access_token_rec: access_token_rec,
    label_name: label_name,
    expected_result: expected_result,
    bypass: bypass,
    label_name: label_name,
    label_id: label_id,
    expected_result: expected_result
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
      assert "/gmail/v1/users/me/labels/#{label_id}" == conn.request_path
      assert "" == conn.query_string
      assert "PATCH" == conn.method
      {:ok, json} = Poison.encode(patched_label)
      Plug.Conn.resp(conn, 200, json)
    end
    with_mock Gmail.OAuth2, [get_config: fn -> access_token_rec end] do
      {:ok, label} = Gmail.Label.patch(patch_label)
      assert expected_result == label
      assert called Gmail.OAuth2.get_config
    end
  end

  test "handles an error when patching a label", %{
    access_token_rec: access_token_rec,
    bypass: bypass,
    four_hundred_error: four_hundred_error,
    four_hundred_error_content: four_hundred_error_content,
    label_id: label_id
  } do
    new_label_name = "Something Else"
    patch_label = %Gmail.Label{id: label_id, name: new_label_name}
    Bypass.expect bypass, fn conn ->
      assert "/gmail/v1/users/me/labels/#{label_id}" == conn.request_path
      assert "" == conn.query_string
      {:ok, json} = Poison.encode(four_hundred_error)
      Plug.Conn.resp(conn, 200, json)
    end
    with_mock Gmail.OAuth2, [get_config: fn -> access_token_rec end] do
      {:error, error_detail} = Gmail.Label.patch(patch_label)
      assert four_hundred_error_content == error_detail
      assert called Gmail.OAuth2.get_config
    end
  end

end
