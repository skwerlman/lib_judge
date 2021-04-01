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
end
