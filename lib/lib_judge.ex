defmodule LibJudge do
  @moduledoc """
  Documentation for `LibJudge`.
  """
  use Application
  alias LibJudge.Tokenizer
  alias LibJudge.Versions

  @spec get!(:current | String.t(), boolean, String.t()) :: String.t()
  defdelegate get!(version, allow_online \\ true, prefix \\ "priv/data/"), to: Versions

  @spec tokenize(String.t()) :: [Tokenizer.token()]
  defdelegate tokenize(text), to: Tokenizer

  @doc false
  @spec start(any, any) :: {:error, any} | {:ok, pid}
  def start(_type, _args) do
    opts = [
      strategy: :one_for_one
    ]

    children = [
      {Finch, name: LibJudge.HTTPClient}
    ]

    Supervisor.start_link(children, opts)
  end
end
