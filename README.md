![Elixir CI](https://github.com/skwerlman/lib_judge/workflows/Elixir%20CI/badge.svg?branch=master)

# LibJudge

A library supplying programmatic access to the MTG Comprehensive Rules

## Installation

Add `lib_judge` to your mixfile:

```elixir
defp deps do
[
    {:lib_judge, "~> 0.4.0"}
]
end
```

## Quick Start

```elixir
# Download the current rules
current_rules = LibJudge.get!(:current)

# Download a specific rules version
specific_rules = LibJudge.get!("20210712")

# Tokenize the rules for filtering
tokens = LibJudge.tokenize(specific_rules)

# Filter the rules for what you want
alias LibJudge.Filter
filter =
  Filter.all([
    Filter.token_type(:rule),
    Filter.body_contains("controlled player"),
    Filter.has_examples()
  ])

# Finds rule 718.5.
filtered_rules = Enum.filter(tokens, filter)
```

## Documentation

The full documentation is available [here](https://hexdocs.pm/lib_judge/readme.html).

## Limitations

There are a few things I'd like to implement,
but haven't been able to for one reason or another,
as well as things which would be nice but can't be done
for technical reasons.

Currently, these are:

- There is no way to list all versions of the MTG Comprehensive Rules
- The set of filters is less complete than it could be, and focuses on `:rule` tokens
- The Glossary of the Comp Rules is simply discarded instead of tokenized
- The shape of tokens is a little wierd
- Some terminology overlaps. In particular, "rule" has several meanings
- Testing doesn't cover nearly as much as I'd like it to

Additionally, there are a number of API improvements
I'd like to make before publishing a 1.0 version.
