ExUnit.start

defmodule Gmail.MessageAttachmentTest do
  use ExUnit.Case
  import Mock

  setup do
    user_id = "user@example.com"
    access_token = "xxx-xxx-xxx"
    bypass = Bypass.open
    Application.put_env :gmail, :api, %{url: "http://localhost:#{bypass.port}/gmail/v1/"}
    Gmail.User.stop_mail(user_id)

    with_mock Gmail.OAuth2, [refresh_access_token: fn(_) -> {access_token, 100000000000000} end] do
      {:ok, _server_pid} = Gmail.User.start_mail(user_id, "dummy-refresh-token")
    end

    {
      :ok, 
      access_token: access_token,
      bypass: bypass,
      user_id: user_id,
    }
  end

  test "gets message attachment", state do
    attachment_id = "22222"
    message_id = "11111"
    result = %{
      size: 30,
      data: "VGhpcyBpcyBhIHRlc3QgdGV4dCBkb2N1bWVudC4K"
    }

    Bypass.expect state[:bypass], fn conn ->
      assert "/gmail/v1/users/#{state[:user_id]}/messages/#{message_id}/attachments/#{attachment_id}" == conn.request_path

      assert "" == conn.query_string

      assert {"authorization", "Bearer #{state[:access_token]}"} in conn.req_headers

      assert "GET" == conn.method

      {:ok, json} = Poison.encode(result)

      Plug.Conn.resp(conn, 200, json)
    end

    {:ok, result} = Gmail.User.attachment(state[:user_id], message_id, attachment_id)

    assert result == %Gmail.MessageAttachment{size: 30, data: "VGhpcyBpcyBhIHRlc3QgdGV4dCBkb2N1bWVudC4K"}
  end
end
