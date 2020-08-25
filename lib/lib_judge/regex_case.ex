defmodule LibJudge.RegexCase do
  @moduledoc false
  defmacro regex_case(string, do: lines) do
    new_lines =
      Enum.map(lines, fn {:->, context, [[regex], result]} ->
        condition = quote do: String.match?(unquote(string), unquote(regex))
        {:->, context, [[condition], result]}
      end)

    # Base case if nothing matches; "cond" complains otherwise.
    base_case = quote do: (true -> nil)
    lines = new_lines ++ base_case

    quote do
      # Any use of this macro will insert more conditions,
      # but credo can't know that ahead of time
      # credo:disable-for-next-line Credo.Check.Refactor.CondStatements
      cond do
        unquote(lines)
      end
    end
  end
end
