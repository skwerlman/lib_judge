defmodule LibJudgeVersionsTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  alias LibJudge.Versions
  doctest LibJudge.Versions

  describe "rule fetcher" do
    test "can fetch :current version" do
      output = capture_log(fn -> Versions.get!(:current) end)
      assert String.contains?(output, "Fetching current rules version...")
      assert String.contains?(output, "Reading locally cached rules version")
    end

    test "can fetch a specified version" do
      File.rm("priv/data/MagicCompRules\ 20200601.txt")
      output = capture_log(fn -> Versions.get!("20200601") end)
      assert String.contains?(output, "Reading locally cached rules version \"20200601\"")
    end

    test "can fetch a cached copy while allow_online is false" do
      output = capture_log(fn -> Versions.get!("20200601", false) end)
      assert String.contains?(output, "Reading locally cached rules version \"20200601\"")
    end

    test "raises when trying to go online while allow_online is false" do
      assert_raise RuntimeError, fn -> Versions.get!(:current, false) end
      assert_raise RuntimeError, fn -> Versions.get!("20190125", false) end
    end

    test "raises when trying to get a file that doesnt exist" do
      assert_raise RuntimeError, fn -> Versions.get!("00000000") end
    end
  end
end
