defmodule LibJudge.Versions do
  @moduledoc """
  TODO
  """
  require Logger

  @finch_client LibJudge.HTTPClient

  @wizards_rules_page "https://magic.wizards.com/en/game-info/gameplay/rules-and-formats/rules"

  @version_regex ~r/%20(\d{8})\./

  @doc """
  Gets the Magic: The Gathering Comprehensive Rules for the given version.

  If the rules cannot be found locally and `allow_online` is `true`,
  this attempts to download them from Wizards.

  Versions are either a date written as "YYYYMMDD", or the atom `:current`.

  If the version is `:current` and `allow_online` is `true`, the
  current version is obtained from Wizards, and the latest rules are
  downloaded.
  """
  @spec get!(version :: String.t() | :current, boolean) :: String.t() | no_return
  def get!(ver, allow_online \\ true) do
    fname = ["priv/data/MagicCompRules ", ver, ".txt"]

    if ver != :current and File.exists?(fname) do
      Logger.info("Reading locally cached rules version #{inspect ver}")
      File.read!(fname)
    else
      get_online(ver, allow_online)
    end
  end

  defp get_online(:current, allow_online) when allow_online == false do
    raise "cannot get current version without going online!"
  end

  defp get_online(ver, allow_online) when allow_online == false do
    raise "cannot find \"priv/data/MagicCompRules #{ver}.txt\" and not allowed to look online!"
  end

  defp get_online(:current, allow_online) when allow_online == true do
    ver = get_current_ver()
    get!(ver, allow_online)
  end

  defp get_online(ver, allow_online) when allow_online == true do
    Logger.info("Fetching rules version #{inspect ver}...")
    txt_url = get_url_from_version(ver)

    txt_ver =
      @version_regex
      |> Regex.run(txt_url)
      |> Enum.at(1)

    resp =
      :get
      |> Finch.build(txt_url)
      |> Finch.request(@finch_client)

    case resp do
      {:ok, %{status: 200, body: body}} ->
        _ = File.write(["priv/data/MagicCompRules ", txt_ver, ".txt"], body)
        get!(txt_ver, false)

      {:ok, %{status: status}} ->
        raise "couldn't get version #{txt_ver}: HTTP #{status}"

      {:error, reason} ->
        raise reason
    end
  end

  defp get_current_ver() do
    Logger.info("Fetching current rules version...")
    resp =
      :get
      |> Finch.build(@wizards_rules_page)
      |> Finch.request(@finch_client)

    url =
      case resp do
        {:ok, %{status: 200, body: body}} ->
          body
          |> Floki.parse_document!()
          |> Floki.find("a[href$=\".txt\"]")
          |> Floki.attribute("href")
          |> hd()

        {:ok, %{status: status}} ->
          raise "couldn't get current version: HTTP #{status}"

        {:error, reason} ->
          raise reason
      end

    @version_regex
    |> Regex.run(url)
    |> Enum.at(1)
  end

  defp get_url_from_version(version) do
    year = String.slice(version, 0..3)
    "https://media.wizards.com/#{year}/downloads/MagicCompRules%20#{version}.txt"
  end
end
