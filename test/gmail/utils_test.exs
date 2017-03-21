ExUnit.start

defmodule Gmail.UtilsTest do
  use ExUnit.Case
  alias Gmail.Utils

  test "loads config" do
    assert 100 == Utils.load_config(:thread, :pool_size)
  end

  test "loads config with a default" do
    assert 101 == Utils.load_config(:thread, :other_pool_size, 101)
  end

  test "load non existent config with a default" do
    assert 102 == Utils.load_config(:absent, :pool_size, 102)
  end

end

