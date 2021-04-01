defmodule LibJudge.Tokenizer do
  @moduledoc """
  Tokenizer for the MTG Comprehensive Rules
  """
  alias LibJudge.Rule
  alias LibJudge.Util

  @type title :: {:title, String.t()}
  @type effective_date :: {:effective_date, Date.t()}
  @type intro :: {:intro, String.t()}
  @type contents :: {:contents, [rule | String.t()]}
  @type rule ::
          {:rule,
           {type :: Rule.rule_type(), rule :: Rule.t(), body :: String.t(),
            examples :: [String.t()]}}
  @type glossary :: {:glossary, [glossary_item]}
  @type glossary_item :: {name :: String.t(), definition :: String.t()}
  @type token ::
          title
          | effective_date
          | intro
          | contents
          | rule
          | glossary

  @spec tokenize(binary) :: [token]
  # ignore BOMs
  def tokenize(<<"\uFEFF", rest::binary>>), do: tokenize(rest)

  def tokenize(string) when is_binary(string) do
    string
    |> String.replace("\r\n", "\n")
    |> tokenize([])
    |> Enum.reverse()
  end

  defp tokenize(text, tokens)

  defp tokenize(<<"Magic: The Gathering Comprehensive Rules", rest::binary>>, tokens) do
    tokenize(rest, [{:title, "Magic: The Gathering Comprehensive Rules"} | tokens])
  end

  defp tokenize(<<"These rules are effective as of ", rest_with_date::binary>>, tokens) do
    [date, rest] = String.split(rest_with_date, ".", parts: 2)

    [month, day, year] =
      date
      |> String.split(" ", parts: 3)
      |> Stream.map(&String.trim(&1, ","))
      |> Enum.map(&Util.date_map(&1))

    {:ok, parsed_date} = Date.new(year, month, day)

    tokenize(rest, [{:effective_date, parsed_date} | tokens])
  end

  defp tokenize(<<"Introduction\n\n", rest_with_intro::binary>>, tokens) do
    [intro, rest] = take_until(rest_with_intro, "\n\nContents")
    tokenize(rest, [{:intro, intro} | tokens])
  end

  defp tokenize(<<"Contents", rest_with_contents::binary>>, tokens) do
    [contents_string, rest] = take_until(rest_with_contents, "1. Game Concepts\n\n")
    contents = tokenize(String.trim(contents_string, "\n"))
    tokenize(rest, [{:contents, contents} | tokens])
  end

  # rules like: 1. <body>
  defp tokenize(<<cat::utf8, ". ", rest_with_body::binary>>, tokens) when cat in 48..57 do
    category_tokenize(cat, rest_with_body, tokens)
  end

  # rules like: 100. <body>
  defp tokenize(
         <<cat::utf8, subcat::binary-size(2), ". ", rest_with_body::binary>>,
         tokens
       )
       when cat in 48..57 do
    subcategory_tokenize(cat, subcat, rest_with_body, tokens)
  end

  # rules like: 100.1. <body>
  defp tokenize(
         <<cat::utf8, subcat::binary-size(2), ".", rule::binary-size(1), ". ",
           rest_with_body::binary>>,
         tokens
       )
       when cat in 48..57 do
    rule_tokenize(cat, subcat, rule, rest_with_body, tokens)
  end

  # rules like: 100.10. <body>
  defp tokenize(
         <<cat::utf8, subcat::binary-size(2), ".", rule::binary-size(2), ". ",
           rest_with_body::binary>>,
         tokens
       )
       when cat in 48..57 do
    rule_tokenize(cat, subcat, rule, rest_with_body, tokens)
  end

  # rules like: 100.100. <body>
  defp tokenize(
         <<cat::utf8, subcat::binary-size(2), ".", rule::binary-size(3), ". ",
           rest_with_body::binary>>,
         tokens
       )
       when cat in 48..57 do
    rule_tokenize(cat, subcat, rule, rest_with_body, tokens)
  end

  # rules like: 100.1a <body>
  defp tokenize(
         <<cat::utf8, subcat::binary-size(2), ".", rule::binary-size(1), subrule::utf8, " ",
           rest_with_body::binary>>,
         tokens
       )
       when cat in 48..57 and subrule in 97..122 do
    subrule_tokenize(cat, subcat, rule, subrule, rest_with_body, tokens)
  end

  # rules like: 100.10a <body>
  defp tokenize(
         <<cat::utf8, subcat::binary-size(2), ".", rule::binary-size(2), subrule::utf8, " ",
           rest_with_body::binary>>,
         tokens
       )
       when cat in 48..57 and subrule in 97..122 do
    subrule_tokenize(cat, subcat, rule, subrule, rest_with_body, tokens)
  end

  # rules like: 100.100a <body>
  defp tokenize(
         <<cat::utf8, subcat::binary-size(2), ".", rule::binary-size(3), subrule::utf8, " ",
           rest_with_body::binary>>,
         tokens
       )
       when cat in 48..57 and subrule in 97..122 do
    subrule_tokenize(cat, subcat, rule, subrule, rest_with_body, tokens)
  end

  # strip leading newlines
  defp tokenize(<<"\n", rest::binary>>, tokens) do
    tokenize(rest, tokens)
  end

  # end tokenization
  defp tokenize(string, [hd | _] = tokens) do
    IO.puts(inspect(String.slice(string, 0..9)))
    IO.puts(inspect(hd))
    tokens
  end

  defp category_tokenize(cat, rest_with_body, tokens) do
    [body, rest] = String.split(rest_with_body, "\n", parts: 2)

    rule = %Rule{
      category: <<cat>>,
      type: :category
    }

    tokenize(rest, [{:rule, {:category, rule, body, []}} | tokens])
  end

  defp subcategory_tokenize(cat, subcat, rest_with_body, tokens) do
    [body, rest_with_examples] = String.split(rest_with_body, "\n", parts: 2)
    {examples, rest} = take_examples(rest_with_examples)

    rule = %Rule{
      category: <<cat>>,
      subcategory: subcat,
      type: :subcategory
    }

    tokenize(rest, [
      {:rule, {:subcategory, rule, body, examples}}
      | tokens
    ])
  end

  defp rule_tokenize(cat, subcat, rule, rest_with_body, tokens) do
    [body_part, rest_with_continuation] = String.split(rest_with_body, "\n", parts: 2)
    {body, rest_with_examples} = continue(body_part, rest_with_continuation)
    {examples, rest} = take_examples(rest_with_examples)

    rule = %Rule{
      category: <<cat>>,
      subcategory: subcat,
      rule: rule,
      type: :rule
    }

    tokenize(rest, [
      {:rule, {:rule, rule, body, examples}}
      | tokens
    ])
  end

  defp subrule_tokenize(cat, subcat, rule, subrule, rest_with_body, tokens) do
    [body_part, rest_with_continuation] = String.split(rest_with_body, "\n", parts: 2)
    {body, rest_with_examples} = continue(body_part, rest_with_continuation)
    {examples, rest} = take_examples(rest_with_examples)

    rule = %Rule{
      category: <<cat>>,
      subcategory: subcat,
      rule: rule,
      subrule: <<subrule>>,
      type: :subrule
    }

    tokenize(rest, [
      {:rule, {:subrule, rule, body, examples}}
      | tokens
    ])
  end

  defp take_until(string, marker) do
    [taken, rest_no_marker] = String.split(string, marker, parts: 2)
    rest = marker <> rest_no_marker
    [taken, rest]
  end

  defp take_examples(bin), do: take_examples([], bin)

  defp take_examples(ex, <<"\n", bin::binary>>), do: take_examples(ex, bin)
  defp take_examples(ex, <<" \n", bin::binary>>), do: take_examples(ex, bin)

  defp take_examples(ex, <<"Example: ", rest::binary>>) do
    [example, rest] = take_until(rest, "\n")
    take_examples([example | ex], rest)
  end

  defp take_examples(ex, bin), do: {ex, bin}

  defp continue(rule, next) do
    case take_continuation(next) do
      {"", rest} -> {rule, rest}
      {cont, rest} -> {"#{rule}\n#{cont}", rest}
    end
  end

  defp take_continuation(bin), do: take_continuation([], bin)

  defp take_continuation(cont, <<"     ", bin::binary>>) do
    [continuation, rest] = take_until(bin, "\n")
    take_continuation([continuation | cont], rest)
  end

  defp take_continuation(cont, bin) do
    continuation = reverse_join(cont, "\n")

    {continuation, bin}
  end

  defp reverse_join(list, join) do
    reverse_join(list, join, "")
  end

  defp reverse_join([], _join, acc), do: acc
  defp reverse_join([this | rest], join, acc), do: reverse_join(rest, join, this <> join <> acc)
end
