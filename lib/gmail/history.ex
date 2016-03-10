defmodule Gmail.History do

  @moduledoc """
  Lists the history of all changes to the given mailbox.
  """

  import Gmail.Base
  alias Gmail.{Helper}

  @doc """
  Lists the history of all changes to the given mailbox. History results are returned in
  chronological order (increasing `historyId`).
  """
  @spec list(String.t, map) :: {atom, String.t, String.t}
  def list(user_id, params) do
    path = if Enum.empty?(params) do
      "users/#{user_id}/history"
    else
      available_options = [:label_id, :max_results, :page_token, :start_history_id]
      query =
        params
        |> Map.keys
        |> Enum.filter(fn key -> key in available_options end)
        |> Enum.reduce(Map.new, fn key, query ->
          string_key = Helper.camelize(key)
          val = if is_list(params[key]) do
            Enum.join(params[key], ",")
          else
            params[key]
          end
          Map.put(query, string_key, val)
        end)
      if Enum.empty?(query) do
        "users/#{user_id}/history"
      else
        "users/#{user_id}/history?#{URI.encode_query(query)}"
      end
    end
    {:get, base_url, path}
  end

end
