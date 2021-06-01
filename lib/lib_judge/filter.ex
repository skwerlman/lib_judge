defmodule LibJudge.Filter do
  @moduledoc """
  A collection of filters to do common searches on rules.

  Each filter returns a single-argument function designed to be
  used with `Enum.filter/2`.
  """
  alias LibJudge.Rule
  alias LibJudge.Tokenizer
  require Logger

  @type filter :: (Tokenizer.rule() -> boolean)

  @spec rule_is(String.t()) :: (Tokenizer.rule() -> boolean)
  def rule_is(rule_str) do
    {:ok, rule} = Rule.from_string(rule_str)

    fn
      {:rule, {_type, ^rule, _body, _examples}} ->
        true

      _ ->
        false
    end
  rescue
    _ -> fn _ -> false end
  end

  @spec rule_starts_with(String.t()) :: filter
  def rule_starts_with(prefix) do
    fn
      {:rule, {_type, rule, _body, _examples}} ->
        case Rule.to_string(rule) do
          {:ok, string} -> String.starts_with?(string, prefix)
          _ -> false
        end

      _ ->
        false
    end
  end

  @spec rule_type(Rule.rule_type()) :: filter
  def rule_type(type) do
    fn
      {:rule, {^type, %Rule{type: ^type}, _body, _examples}} -> true
      _ -> false
    end
  end

  @spec body_contains(String.t()) :: filter
  def body_contains(text) do
    fn
      {:rule, {_type, _rule, body, _examples}} -> String.contains?(body, text)
      _ -> false
    end
  end

  @spec has_examples() :: filter
  def has_examples do
    fn
      {:rule, {_type, _rule, _body, [_at_least_one_example]}} -> true
      _ -> false
    end
  end

  @spec body_matches(Regex.t()) :: filter
  def body_matches(regex) do
    fn
      {:rule, {_type, _rule, body, _examples}} -> Regex.match?(regex, body)
      _ -> false
    end
  end

  @spec rule_matches(Regex.t()) :: filter
  def rule_matches(regex) do
    fn
      {:rule, {_type, rule, _body, _examples}} -> Regex.match?(regex, rule)
      _ -> false
    end
  end

  @spec example_matches(Regex.t()) :: filter
  def example_matches(regex) do
    fn
      {:rule, {_type, _rule, _body, examples}} ->
        Enum.reduce(examples, false, fn x, acc -> Regex.match?(regex, x) || acc end)

      _ ->
        false
    end
  end

  @spec either(filter, filter) :: filter
  def either(filter1, filter2) do
    fn x ->
      filter1.(x) or filter2.(x)
    end
  end

  @spec any([filter]) :: filter
  def any(filters) do
    Enum.reduce(
      filters,
      &either/2
    )
  end

  @spec both(filter, filter) :: filter
  def both(filter1, filter2) do
    fn x ->
      filter1.(x) and filter2.(x)
    end
  end

  @spec all([filter]) :: filter
  def all(filters) do
    Enum.reduce(
      filters,
      &both/2
    )
  end
end
