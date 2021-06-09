defmodule LibJudgeTest.Models.Rules do
  use PropCheck

  def rule_type do
    let type <- oneof([:category, :subcategory, :rule, :subrule]) do
      type
    end
  end

  def subrule_letter do
    let char <- choose(0x61, 0x7A) do
      to_string([char])
    end
  end

  def long_subrule_letter do
    let [
      letter <- subrule_letter(),
      letter2 <- subrule_letter()
    ] do
      letter <> letter2
    end
  end

  def rule do
    let [
      cat <- integer(1, 9),
      subcat <- integer(0, 99),
      rule <- integer(1, 999),
      subrule <- subrule_letter(),
      type <- rule_type()
    ] do
      case type do
        :category ->
          %LibJudge.Rule{
            type: :category,
            category: to_string(cat),
            subcategory: nil,
            rule: nil,
            subrule: nil
          }

        :subcategory ->
          %LibJudge.Rule{
            type: :subcategory,
            category: to_string(cat),
            subcategory: subcat |> to_string() |> String.pad_leading(2, "0"),
            rule: nil,
            subrule: nil
          }

        :rule ->
          %LibJudge.Rule{
            type: :rule,
            category: to_string(cat),
            subcategory: subcat |> to_string() |> String.pad_leading(2, "0"),
            rule: to_string(rule),
            subrule: nil
          }

        :subrule ->
          %LibJudge.Rule{
            type: :subrule,
            category: to_string(cat),
            subcategory: subcat |> to_string() |> String.pad_leading(2, "0"),
            rule: to_string(rule),
            subrule: subrule
          }
      end
    end
  end

  def long_subrule do
    let [
      cat <- integer(1, 9),
      subcat <- integer(0, 99),
      rule <- integer(1, 999),
      subrule <- long_subrule_letter()
    ] do
      %LibJudge.Rule{
        type: :subrule,
        category: to_string(cat),
        subcategory: subcat |> to_string() |> String.pad_leading(2, "0"),
        rule: to_string(rule),
        subrule: subrule
      }
    end
  end

  def maybe_bad_rule do
    let [
      cat <- oneof([integer(1, 9), exactly(nil)]),
      subcat <- oneof([integer(0, 99), exactly(nil)]),
      rule <- oneof([integer(1, 999), exactly(nil)]),
      subrule <- oneof([subrule_letter(), long_subrule_letter(), exactly(nil)]),
      type <- oneof([rule_type(), exactly(nil)])
    ] do
      pcat =
        if cat do
          to_string(cat)
        end

      psubcat =
        if subcat do
          subcat
          |> to_string()
          |> String.pad_leading(2, "0")
        end

      prule =
        if rule do
          to_string(rule)
        end

      %LibJudge.Rule{
        type: type,
        category: pcat,
        subcategory: psubcat,
        rule: prule,
        subrule: subrule
      }
    end
  end

  def cat_str do
    let cat <- integer(1, 9) do
      {to_string(cat) <> ".", :category}
    end
  end

  def subcat_str do
    let [
      cat <- integer(1, 9),
      sc1 <- integer(0, 9),
      sc2 <- integer(0, 9),
      ending <- oneof(["", "."])
    ] do
      {to_string(cat) <>
         to_string(sc1) <>
         to_string(sc2) <>
         ending, :subcategory}
    end
  end

  def rule_str do
    let [
      cat <- integer(1, 9),
      sc1 <- integer(0, 9),
      sc2 <- integer(0, 9),
      rule <- integer(1, 999),
      ending <- oneof(["", "."])
    ] do
      {to_string(cat) <>
         to_string(sc1) <>
         to_string(sc2) <>
         "." <>
         to_string(rule) <>
         ending, :rule}
    end
  end

  def subrule_str do
    let [
      cat <- integer(1, 9),
      sc1 <- integer(0, 9),
      sc2 <- integer(0, 9),
      rule <- integer(1, 999),
      subrule <- subrule_letter()
    ] do
      {to_string(cat) <>
         to_string(sc1) <>
         to_string(sc2) <>
         "." <>
         to_string(rule) <>
         subrule, :subrule}
    end
  end

  def long_subrule_str do
    let [
      cat <- integer(1, 9),
      sc1 <- integer(0, 9),
      sc2 <- integer(0, 9),
      rule <- integer(1, 999),
      subrule <- subrule_letter(),
      subrule2 <- subrule_letter()
    ] do
      {to_string(cat) <>
         to_string(sc1) <>
         to_string(sc2) <>
         "." <>
         to_string(rule) <>
         subrule <>
         subrule2, :subrule}
    end
  end

  def any_rule_str do
    oneof([
      cat_str(),
      subcat_str(),
      rule_str(),
      subrule_str()
    ])
  end

  def many_rules do
    let l <- list(any_rule_str()) do
      {rules, types} = Enum.unzip(l)
      {Enum.join(rules, " "), types}
    end
  end
end
