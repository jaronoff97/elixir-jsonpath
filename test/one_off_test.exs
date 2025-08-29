defmodule OneOffTest do
  use ExUnit.Case, async: true

  describe "one off cases" do
    test "space between bracket and selector" do
      t = ~s({
        "name": "space between bracket and selector",
        "selector": "$[ 'a']",
        "document": {
          "a": "ab"
        },
        "result": [
          "ab"
        ],
        "result_paths": [
          "$['a']"
        ],
        "tags": [
          "whitespace"
        ]
      })
      test_case = Jason.decode!(t)

      assert [{result_path, result}] =
               JsonPath.query(test_case["document"], test_case["selector"])

      assert [result_path] == test_case["result_paths"]
      assert [result] == test_case["result"]
    end

    test "spaces in an absolute singular selector" do
      t = ~s({
        "name": "at the end",
        "selector": "$[?search(@.a, 'a.*'\)]",
        "document": [
          {
            "a": "the end is ab"
          }
        ],
        "result": [
          {
            "a": "the end is ab"
          }
        ],
        "result_paths": [
          "$[0]"
        ],
        "tags": [
          "function",
          "search"
        ]
      })
      test_case = Jason.decode!(t)

      assert [{result_path, result}] =
               JsonPath.query(test_case["document"], test_case["selector"])

      assert [result_path] == test_case["result_paths"]
      assert [result] == test_case["result"]
    end

    test "return between parenthesis and arg" do
      t = ~s({
        "name": "return between parenthesis and arg",
        "selector": "$[?count(\\r@.*\)==1]",
        "document": [
          {
            "a": 1
          },
          {
            "b": 2
          },
          {
            "a": 2,
            "b": 1
          }
        ],
        "result": [
          {
            "a": 1
          },
          {
            "b": 2
          }
        ],
        "result_paths": [
          "$[0]",
          "$[1]"
        ],
        "tags": [
          "whitespace",
          "function",
          "count"
        ]
      })
      test_case = Jason.decode!(t)

      assert [{first_result_path, first_result}, {second_result_path, second_result}] =
               JsonPath.query(test_case["document"], test_case["selector"])

      assert [first_result_path, second_result_path] == test_case["result_paths"]
      assert [first_result, second_result] == test_case["result"]
    end

    test "compare to true" do
      data = ~s({
        "name": "less than or equal to true",
        "selector": "$[?@.a<=true]",
        "document": [
          {
            "a": true,
            "d": "e"
          },
          {
            "a": "c",
            "d": "f"
          }
        ],
        "result": [
          {
            "a": true,
            "d": "e"
          }
        ],
        "result_paths": [
          "$[0]"
        ]
      })
      test_case = Jason.decode!(data)

      assert [{first_result_path, first_result}] =
               JsonPath.query(test_case["document"], test_case["selector"])

      assert [first_result_path] == test_case["result_paths"]
      assert [first_result] == test_case["result"]
    end

    test "not-equals null, absent from data" do
      data = ~s({
        "name": "not-equals null, absent from data",
        "selector": "$[?@.a!=null]",
        "document": [
          {
            "d": "e"
          },
          {
            "a": "c",
            "d": "f"
          }
        ],
        "result": [
          {
            "d": "e"
          },
          {
            "a": "c",
            "d": "f"
          }
        ],
        "result_paths": [
          "$[0]",
          "$[1]"
        ]
      })
      test_case = Jason.decode!(data)

      result_pairs =
        JsonPath.query(test_case["document"], test_case["selector"])

      assert length(result_pairs) == length(test_case["result"])

      Enum.with_index(result_pairs)
      |> Enum.map(fn {{path, res}, index} ->
        assert path == Enum.at(test_case["result_paths"], index)
        assert res == Enum.at(test_case["result"], index)
      end)
    end

    test "equals, empty node list and special nothing" do
      t = ~s({
        "name": "equals, empty node list and special nothing",
        "selector": "$[?@.a == length(@.b\)]",
        "document": [
          {
            "a": 1
          },
          {
            "b": 2
          },
          {
            "c": 3
          }
        ],
        "result": [
          {
            "b": 2
          },
          {
            "c": 3
          }
        ],
        "result_paths": [
          "$[1]",
          "$[2]"
        ],
        "tags": [
          "whitespace",
          "function"
        ]
      })
      test_case = Jason.decode!(t)
      IO.inspect(JsonPath.tokenize(test_case["selector"]))

      assert [{result_path, result}] =
               JsonPath.query(test_case["document"], test_case["selector"])

      assert [result_path] == test_case["result_paths"]
      assert [result] == test_case["result"]
    end

    test "prom parsing" do
      data = %{
        data: %{
          error: nil,
          result: [
            %{
              values: [
                [1_756_430_193_000, "3"],
                [1_756_430_253_000, "3"],
                [1_756_430_313_000, "3"],
                [1_756_430_373_000, "3"],
                [1_756_430_433_000, "3"],
                [1_756_430_493_000, "3"],
                [1_756_430_553_000, "3"],
                [1_756_430_613_000, "3"],
                [1_756_430_673_000, "3"],
                [1_756_430_733_000, "3"],
                [1_756_430_793_000, "3"],
                [1_756_430_853_000, "3"],
                [1_756_430_913_000, "3"],
                [1_756_430_974_000, "3"],
                [1_756_431_033_000, "3"],
                [1_756_431_093_000, "3"],
                [1_756_431_153_000, "3"],
                [1_756_431_213_000, "3"],
                [1_756_431_273_000, "3"],
                [1_756_431_333_000, "3"],
                [1_756_431_393_000, "3"],
                [1_756_431_453_000, "3"],
                [1_756_431_513_000, "3"],
                [1_756_431_573_000, "3"],
                [1_756_431_633_000, "3"],
                [1_756_431_693_000, "3"],
                [1_756_431_753_000, "3"],
                [1_756_431_813_000, "3"],
                [1_756_431_873_000, "3"],
                [1_756_431_933_000, "3"],
                [1_756_431_993_000, "3"],
                [1_756_432_053_000, "3"],
                [1_756_432_113_000, "3"],
                [1_756_432_173_000, "3"],
                [1_756_432_233_000, "3"],
                [1_756_432_293_000, "3"],
                [1_756_432_353_000, "3"],
                [1_756_432_413_000, "3"]
              ],
              metric: %{"__name__" => "otelcol_exporter_queue_capacity"}
            },
            %{
              values: [
                [1_756_430_193_000, "3"],
                [1_756_430_253_000, "3"],
                [1_756_430_313_000, "3"],
                [1_756_430_373_000, "3"],
                [1_756_430_433_000, "3"],
                [1_756_430_493_000, "3"],
                [1_756_430_553_000, "3"],
                [1_756_430_613_000, "3"],
                [1_756_430_673_000, "3"],
                [1_756_430_733_000, "3"],
                [1_756_430_793_000, "3"],
                [1_756_430_853_000, "3"],
                [1_756_430_913_000, "3"],
                [1_756_430_974_000, "3"],
                [1_756_431_033_000, "3"],
                [1_756_431_093_000, "3"],
                [1_756_431_153_000, "3"],
                [1_756_431_213_000, "3"],
                [1_756_431_273_000, "3"],
                [1_756_431_333_000, "3"],
                [1_756_431_393_000, "3"],
                [1_756_431_453_000, "3"],
                [1_756_431_513_000, "3"],
                [1_756_431_573_000, "3"],
                [1_756_431_633_000, "3"],
                [1_756_431_693_000, "3"],
                [1_756_431_753_000, "3"],
                [1_756_431_813_000, "3"],
                [1_756_431_873_000, "3"],
                [1_756_431_933_000, "3"],
                [1_756_431_993_000, "3"],
                [1_756_432_053_000, "3"],
                [1_756_432_113_000, "3"],
                [1_756_432_173_000, "3"],
                [1_756_432_233_000, "3"],
                [1_756_432_293_000, "3"],
                [1_756_432_353_000, "3"]
              ],
              metric: %{"__name__" => "otelcol_exporter_queue_size"}
            }
          ],
          resultType: "matrix"
        },
        status: "success"
      }

      assert [{result_path, result}] =
               JsonPath.query(data, "$.data.result[*].metric.__name__", key_mode: :both)

      assert length(result_path) > 0
      assert length(result) > 0
    end

    test "double quotes, surrogate pair 😀" do
      result_pairs =
        JsonPath.query(
          %{
            "😀": "A"
          },
          "$[\"\\uD83D\\uDE00\"]"
        )

      assert [{"$['😀']", "A"}] == result_pairs
    end

    test "filter on primitive value with length" do
      data = ["foo"]
      result = JsonPath.query(data, "$..[?length(@) == 3]")
      assert result == [{"$[0]", "foo"}]
    end

    test "filter on string value" do
      data = ["hello"]
      assert [{"$[0]", "hello"}] = JsonPath.query(data, "$..[?length(@) == 5]")
    end

    test "filter on primitive descendant only" do
      data = [%{a: "hello"}]
      assert [{"$[0]['a']", "hello"}] = JsonPath.query(data, "$..[?length(@) == 5]")
    end
  end
end
