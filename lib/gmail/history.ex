defmodule Gmail.History do

  @moduledoc """
  Lists the history of all changes to the given mailbox.
  """

  import Gmail.Base

  @doc """
  Lists the history of all changes to the given mailbox. History results are returned in
  chronological order (increasing `historyId`).
  """
  @spec list(String.t, map) :: {atom, String.t, String.t}
  def list(user_id, params) do
    available_options = [:label_id, :max_results, :page_token, :start_history_id]
    path = querify_params("users/#{user_id}/history", available_options, params)
    {:get, base_url, path}
  end

end
