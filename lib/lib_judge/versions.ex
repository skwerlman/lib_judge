defmodule LibJudge.Versions do
  @moduledoc """
  TODO
  """
  require Logger

  @finch_client LibJudge.HTTPClient

  @wizards_rules_page "https://magic.wizards.com/en/rules"

  @version_regex ~r/(?:%20| |MagicCompRules)(\d{8})\./

  @doc """
  Gets the Magic: The Gathering Comprehensive Rules for the given version.

  If the rules cannot be found locally,
  this attempts to download them from Wizards.

  Versions are either a date written as "YYYYMMDD",
  or the atom `:current`. Note that the version
  does not necessarily match the effective date.

  If the version is `:current`, the current version
  is obtained from Wizards, and the latest rules are
  downloaded.

  If `allow_online` is `false`, any action that would
  go over the internet raises an error instead.

  Downloaded rules are cached to `prefix` in addition
  to being returned.
  """
  @spec get!(version :: String.t() | :current, boolean, prefix :: String.t()) ::
          String.t() | no_return
  def get!(ver, allow_online \\ true, prefix \\ "priv/data/")

  def get!(:current, allow_online, prefix) do
    get_online(:current, allow_online, prefix)
  end

  def get!(ver, allow_online, prefix) do
    fname = [prefix, "MagicCompRules ", ver, ".txt"]

    if File.exists?(fname) do
      Logger.info("Reading locally cached rules version #{inspect(ver)}")
      File.read!(fname)
    else
      get_online(ver, allow_online, prefix)
    end
  end

  defp get_online(:current, allow_online, _prefix) when allow_online == false do
    raise "cannot get current version without going online!"
  end

  defp get_online(ver, allow_online, prefix) when allow_online == false do
    raise "cannot find \"#{prefix}MagicCompRules #{ver}.txt\" and not allowed to look online!"
  end

  defp get_online(:current, allow_online, prefix) when allow_online == true do
    ver = get_current_ver()

    get!(ver, allow_online, prefix)
  end

  defp get_online(ver, allow_online, prefix) when allow_online == true do
    Logger.info("Fetching rules version #{inspect(ver)}...")
    urls = get_urls_from_version(ver)

    vers =
      urls
      |> Enum.map(fn x ->
        case Regex.run(@version_regex, x) do
          nil ->
            nil

          matches ->
            Enum.at(matches, 1)
        end
      end)
      |> Enum.reject(&is_nil/1)

    if vers == [] do
      Logger.error(["we tried the following urls:\n", inspect(urls, pretty: true)])
      raise "unable to extract version info from any url! this is a bug!"
    end

    download(urls, vers, prefix)
  end

  defp download([url | urls], [ver | vers], prefix) do
    resp =
      :get
      |> Finch.build(url)
      |> Finch.request(@finch_client)

    case resp do
      {:ok, %{status: 200, body: body}} ->
        _ = File.write([prefix, "MagicCompRules ", ver, ".txt"], body)
        get!(ver, false, prefix)

      {:ok, %{status: status}} ->
        case urls do
          [] -> raise "couldn't get version #{ver}: HTTP #{status}"
          _ -> download(urls, vers, prefix)
        end

      {:error, reason} ->
        raise reason
    end
  end

  defp get_current_ver do
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

    case Regex.run(@version_regex, url) do
      nil ->
        Logger.error("no match for #{url}")
        raise "unable to extract version info from the url! this is a bug!"

      matches ->
        Enum.at(matches, 1)
    end
  end

  defp get_urls_from_version(version) do
    year = String.slice(version, 0..3)

    [
      "https://media.wizards.com/#{year}/downloads/Comprehensive%20Rules%20#{version}.txt",
      "https://media.wizards.com/#{year}/downloads/MagicComp%20Rules%20#{version}.txt",
      "https://media.wizards.com/#{year}/downloads/MagicCompRules%20#{version}.txt",
      "https://media.wizards.com/#{year}/downloads/MagicCompRules#{version}.txt"
    ]
  end
end
