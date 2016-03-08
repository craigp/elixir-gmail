ExUnit.start

defmodule Gmail.BaseTest do
  use ExUnit.Case

  test "uses the url in the app config if there is one" do
    url = "http://appconfig.example.com"
    Application.put_env :gmail, :api, %{url: url}
    assert Gmail.Base.base_url == url
  end

  test "uses the default base url if nothing is set in the app config" do
    Application.delete_env :gmail, :api
    assert Gmail.Base.base_url == "https://www.googleapis.com/gmail/v1/"
  end

  test "uses the default base url if app config is set but has no url" do
    Application.put_env :gmail, :api, %{nothing: "here"}
    assert Gmail.Base.base_url == "https://www.googleapis.com/gmail/v1/"
  end

end
