defmodule LibJudge.Rule do
  @moduledoc """
  Defines the `Rule` structure and provides methods for generating
  and working with them
  """
  alias LibJudge.Rule.InvalidPartError

  @type rule_type :: :category | :subcategory | :rule | :subrule
  @type t :: %__MODULE__{
          category: String.t(),
          subcategory: String.t(),
          rule: String.t(),
          subrule: String.t(),
          type: rule_type()
        }
  defstruct [:category, :subcategory, :rule, :subrule, :type]

  @rule_regex ~r/\b[1-9](?:\d{2}(?:\.\d{1,3}(?:\-\d{1,3}|[a-z](?:\-[b-z])?)?\b|\.)?|\.)/

  @doc """
  Creates a `Rule` struct from a string

  ## Examples

      iex> LibJudge.Rule.from_string("702.21j")
      {:ok, %LibJudge.Rule{type: :subrule, category: "7", subcategory: "02", rule: "21", subrule: "j"}}
  """
  @spec from_string(String.t()) :: {:ok, t} | {:error, String.t()}
  def from_string(str) when is_binary(str) do
    opts =
      try do
        split!(str)
      rescue
        err in InvalidPartError -> {:error, err}
      end

    case opts do
      {:error, reason} -> {:error, reason}
      _ -> {:ok, struct(__MODULE__, opts)}
    end
  end

  def from_string(_not_a_str) do
    {:error, "input is not a string"}
  end

  @doc """
  Creates a list of `Rule`s referenced in a string

  ## Examples

      iex> LibJudge.Rule.all_from_string("See rules 702.21j and 702.108.")
      {
        :ok,
        [
          %LibJudge.Rule{type: :subrule, category: "7", subcategory: "02", rule: "21", subrule: "j"},
          %LibJudge.Rule{type: :rule, category: "7", subcategory: "02", rule: "108", subrule: nil}
        ]
      }
  """
  @spec all_from_string(String.t()) :: {:ok, [t]} | {:error, String.t()}
  def all_from_string(str) when is_binary(str) do
    # what the fuck wizards
    clean_str = String.replace(str, "–", "-")

    rules =
      @rule_regex
      |> Regex.scan(clean_str)
      |> List.flatten()
      |> Stream.map(&from_string/1)
      |> Stream.filter(fn
        {:ok, _} -> true
        _ -> false
      end)
      |> Enum.map(fn {:ok, x} -> x end)

    {:ok, rules}
  end

  def all_from_string(_not_a_str) do
    {:error, "input is not a string"}
  end

  @doc """
  Turns a `Rule` back into a string

  ## Examples

      iex> LibJudge.Rule.to_string!(%LibJudge.Rule{type: :subrule, category: "7", subcategory: "02", rule: "21", subrule: "j"})
      "702.21j"
  """
  @spec to_string!(t()) :: String.t() | no_return
  def to_string!(rule = %{__struct__: kind}) when kind == __MODULE__ do
    case rule do
      %__MODULE__{
        type: :subrule,
        category: cat,
        subcategory: subcat,
        rule: rule,
        subrule: subrule
      } ->
        validate_cat!(cat)
        validate_subcat!(subcat)
        validate_rule!(rule)
        validate_subrule!(subrule)

        cat <> subcat <> "." <> rule <> subrule

      %__MODULE__{type: :rule, category: cat, subcategory: subcat, rule: rule} ->
        validate_cat!(cat)
        validate_subcat!(subcat)
        validate_rule!(rule)
        cat <> subcat <> "." <> rule <> "."

      %__MODULE__{type: :subcategory, category: cat, subcategory: subcat} ->
        validate_cat!(cat)
        validate_subcat!(subcat)
        cat <> subcat <> "."

      %__MODULE__{type: :category, category: cat} ->
        validate_cat!(cat)
        cat <> "."
    end
  end

  @doc """
  Turns a `Rule` back into a string

  Non-bang variant

  ## Examples

      iex> LibJudge.Rule.to_string(%LibJudge.Rule{type: :category, category: "1"})
      {:ok, "1."}
  """
  @spec to_string(t()) :: {:ok, String.t()} | {:error, reason :: any}
  def to_string(rule) do
    {:ok, to_string!(rule)}
  rescue
    ArgumentError ->
      {:error, {:invalid_rule, "missing properties for type"}}

    err in FunctionClauseError ->
      case err.function do
        :to_string! -> {:error, {:invalid_rule, "not a %Rule{}"}}
        _ -> {:error, err}
      end

    err ->
      {:error, err}
  end

  defp split!(rule = <<cat::utf8, subcat_1::utf8, subcat_2::utf8>>)
       when cat in 48..57 and subcat_1 in 48..57 and subcat_2 in 48..57,
       do: split!(rule <> ".")

  defp split!(<<cat::utf8, ".">>) when cat in 48..57 do
    validate_cat!(<<cat>>)
    [category: <<cat>>, type: :category]
  end

  defp split!(<<cat::utf8, subcat::binary-size(2), ".">>) when cat in 48..57 do
    validate_cat!(<<cat>>)
    validate_subcat!(subcat)
    [category: <<cat>>, subcategory: subcat, type: :subcategory]
  end

  defp split!(<<cat::utf8, subcat::binary-size(2), ".", rule::binary-size(1), ".">>)
       when cat in 48..57 do
    validate_cat!(<<cat>>)
    validate_subcat!(subcat)
    validate_rule!(rule)

    [
      category: <<cat>>,
      subcategory: subcat,
      rule: rule,
      type: :rule
    ]
  end

  defp split!(<<cat::utf8, subcat::binary-size(2), ".", rule::binary-size(2), ".">>)
       when cat in 48..57 do
    validate_cat!(<<cat>>)
    validate_subcat!(subcat)
    validate_rule!(rule)

    [
      category: <<cat>>,
      subcategory: subcat,
      rule: rule,
      type: :rule
    ]
  end

  defp split!(<<cat::utf8, subcat::binary-size(2), ".", rule::binary-size(3), ".">>)
       when cat in 48..57 do
    validate_cat!(<<cat>>)
    validate_subcat!(subcat)
    validate_rule!(rule)

    [
      category: <<cat>>,
      subcategory: subcat,
      rule: rule,
      type: :rule
    ]
  end

  defp split!(<<cat::utf8, subcat::binary-size(2), ".", rule::binary-size(1), subrule::utf8>>)
       when cat in 48..57 and subrule in 97..122 do
    validate_cat!(<<cat>>)
    validate_subcat!(subcat)
    validate_rule!(rule)
    validate_subrule!(<<subrule>>)

    [
      category: <<cat>>,
      subcategory: subcat,
      rule: rule,
      subrule: <<subrule>>,
      type: :subrule
    ]
  end

  defp split!(<<cat::utf8, subcat::binary-size(2), ".", rule::binary-size(2), subrule::utf8>>)
       when cat in 48..57 and subrule in 97..122 do
    validate_cat!(<<cat>>)
    validate_subcat!(subcat)
    validate_rule!(rule)
    validate_subrule!(<<subrule>>)

    [
      category: <<cat>>,
      subcategory: subcat,
      rule: rule,
      subrule: <<subrule>>,
      type: :subrule
    ]
  end

  defp split!(<<cat::utf8, subcat::binary-size(2), ".", rule::binary-size(3), subrule::utf8>>)
       when cat in 48..57 and subrule in 97..122 do
    validate_cat!(<<cat>>)
    validate_subcat!(subcat)
    validate_rule!(rule)
    validate_subrule!(<<subrule>>)

    [
      category: <<cat>>,
      subcategory: subcat,
      rule: rule,
      subrule: <<subrule>>,
      type: :subrule
    ]
  end

  # these are a hack to make not-strictly-correct rule ids like
  # '205.1' (should be '205.1.') work to make this more friendly
  defp split!(<<cat::utf8, subcat::binary-size(2), ".", rule::binary-size(1)>>)
       when cat in 48..57 do
    validate_cat!(<<cat>>)
    validate_subcat!(subcat)
    validate_rule!(rule)

    [
      category: <<cat>>,
      subcategory: subcat,
      rule: rule,
      type: :rule
    ]
  end

  defp split!(<<cat::utf8, subcat::binary-size(2), ".", rule::binary-size(2)>>)
       when cat in 48..57 do
    validate_cat!(<<cat>>)
    validate_subcat!(subcat)
    validate_rule!(rule)

    [
      category: <<cat>>,
      subcategory: subcat,
      rule: rule,
      type: :rule
    ]
  end

  defp split!(<<cat::utf8, subcat::binary-size(2), ".", rule::binary-size(3)>>)
       when cat in 48..57 do
    validate_cat!(<<cat>>)
    validate_subcat!(subcat)
    validate_rule!(rule)

    [
      category: <<cat>>,
      subcategory: subcat,
      rule: rule,
      type: :rule
    ]
  end

  defp split!(str) do
    {:error, "invalid rule: #{inspect(str)}"}
  end

  defp validate_cat!(cat) when is_binary(cat) do
    unless String.match?(cat, ~r/^\d$/) do
      raise InvalidPartError, {:category, cat}
    end
  end

  defp validate_subcat!(subcat) do
    unless String.match?(subcat, ~r/^\d\d$/) do
      raise InvalidPartError, {:subcategory, subcat}
    end
  end

  defp validate_rule!(rule) do
    unless String.match?(rule, ~r/^\d\d?\d?$/) do
      raise InvalidPartError, {:rule, rule}
    end
  end

  defp validate_subrule!(subrule) do
    unless String.match?(subrule, ~r/^[a-z]$/) do
      raise InvalidPartError, {:subrule, subrule}
    end
  end
end

defmodule LibJudge.Rule.InvalidPartError do
  @moduledoc """
  An exception raised when validating `LibJudge.Rule` structs.
  """
  alias __MODULE__
  defexception [:message, :part, :value]

  @doc false
  @impl Exception
  def exception({part, value}) do
    msg = "invalid part:\n\tPart:\t#{inspect(part)}\n\tValue:\t#{inspect(value)}"
    %InvalidPartError{message: msg, part: part, value: value}
  end

  def exception([]) do
    msg = "invalid part"
    %InvalidPartError{message: msg}
  end

  def exception(part) do
    msg = "invalid part:\n\tPart:\t#{inspect(part)}"
    %InvalidPartError{message: msg, part: part}
  end
end
