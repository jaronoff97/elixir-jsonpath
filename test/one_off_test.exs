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
        "name": "spaces in an absolute singular selector",
        "selector": "$..[?length(@\)==length($ [0] .a\)]",
        "document": [
          {
            "a": "foo"
          },
          {}
        ],
        "result": [
          "foo"
        ],
        "result_paths": [
          "$[0]['a']"
        ],
        "tags": [
          "whitespace",
          "function",
          "length"
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

    test "equals self" do
      data = ~s({
        "name": "equals self",
        "selector": "$[?@==@]",
        "document": [
          1,
          null,
          true,
          {
            "a": "b"
          },
          [
            false
          ]
        ],
        "result": [
          1,
          null,
          true,
          {
            "a": "b"
          },
          [
            false
          ]
        ],
        "result_paths": [
          "$[0]",
          "$[1]",
          "$[2]",
          "$[3]",
          "$[4]"
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
