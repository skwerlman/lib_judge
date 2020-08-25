defmodule LibJudge.Filter do
  @moduledoc """
  TODO
  """
  alias __MODULE__
  alias LibJudge.Rule

  @doc false
  defmacro regex_case(string, do: lines) do
    new_lines =
      Enum.map(lines, fn {:->, context, [[regex], result]} ->
        condition = quote do: String.match?(unquote(string), unquote(regex))
        {:->, context, [[condition], result]}
      end)

    # Base case if nothing matches; "cond" complains otherwise.
    base_case = quote do: (true -> false)
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

  @doc false
  defmacro filter(pattern) do
    quote do
      fn
        unquote(pattern) -> true
        _ -> false
      end
    end
  end

  @doc false
  # NOTE: any pattern passed to this MUST use 'here' for the variable
  defmacro regex_filter(pattern, regex) do
    clean_pattern =
      Macro.prewalk(pattern, &Macro.update_meta(&1, fn x -> Keyword.delete(x, :counter) end))

    quote do
      fn
        unquote(clean_pattern) ->
          Filter.regex_case here do
            unquote(regex) -> true
          end

        _ ->
          false
      end
    end
  end

  defmacro rule_starts_with(prefix) do
    quote do
      Filter.filter({:rule, {_, <<unquote(prefix), _::binary()>>, _, _}})
    end
  end

  defmacro rule_type(type) do
    quote do
      Filter.filter({:rule, {unquote(type), _, _, _}})
    end
  end

  defmacro has_examples do
    quote do
      Filter.filter({:rule, {_, _, _, [_ | _]}})
    end
  end

  defmacro body_matches(regex) do
    quote do
      Filter.regex_filter({_, {_, _, here, _}}, unquote(regex))
    end
  end

  defmacro rule_matches(regex) do
    quote do
      Filter.regex_filter({_, {_, here, _, _}}, unquote(regex))
    end
  end

  # these ones are only macros for consistency

  defmacro example_matches(regex) do
    quote do
      fn
        {_, {_, _, _, examples}} ->
          Enum.reduce(examples, false, fn x, acc -> Regex.match?(unquote(regex), x) || acc end)

        _ ->
          false
      end
    end
  end
end
