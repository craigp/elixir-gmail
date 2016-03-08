ExUnit.start

defmodule Gmail.UserTest do

  use ExUnit.Case
  import Mock

  setup do
    user_id = "user12@example.com"
    {:ok, %{
        user_id: user_id
      }}
  end

  test "stops a user process instance that has been started", %{user_id: user_id} do
    with_mock Gmail.OAuth2, [refresh_access_token: fn(_) -> {"not-an-access-token", 100000000000000} end] do
      {:ok, _pid} = Gmail.User.start_mail(user_id, "not-a-refresh-token")
      assert nil != Process.whereis(String.to_atom(user_id))
      assert :ok == Gmail.User.stop_mail(user_id)
    end
  end

  test "attempts to stop a user process instance that has not been started", %{user_id: user_id} do
    assert nil == Process.whereis(String.to_atom(user_id))
    assert :ok == Gmail.User.stop_mail(user_id)
  end

end
