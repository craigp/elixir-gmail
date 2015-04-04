defmodule Gmail.Thread do

  import Gmail.Base

  defstruct id: "", snippet: "", history_id: "", messages: []

  def get(id), do: get("me", id)

  def get(user_id, id) do
    case do_get("users/#{user_id}/threads/#{id}") do
      {:ok, %{"id" => id, "historyId" => history_id, "messages" => messages}} ->
        %Gmail.Thread{id: id, history_id: history_id, messages: Enum.map(messages, &Gmail.Message.convert/1)}
    end
  end

  # TODO do something useful with the next_page_token to allow paging
  # "nextPageToken" => "zz10338130669795929810", "resultSizeEstimate" => 0, "threads" => []
  def list(user_id \\ "me") do
    case do_get("users/#{user_id}/threads") do
      {:ok, %{"threads" => raw_threads, "nextPageToken" => _next_page_token}} ->
        Enum.map(raw_threads,
          fn(%{"id" => id, "historyId" => history_id, "snippet" => snippet}) ->
            %Gmail.Thread{id: id, history_id: history_id, snippet: snippet}
          end)
    end
  end

end
