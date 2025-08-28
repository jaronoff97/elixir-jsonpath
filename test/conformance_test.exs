defmodule JsonPathConformanceTest do
  use ExUnit.Case, async: true

  fixtures = Path.wildcard("test/fixtures/**/*.json")

  for file <- fixtures do
    describe "JSONPath conformance: #{file}" do
      setup do
        {:ok, json} = File.read(unquote(file))
        {:ok, data} = Jason.decode(json)
        %{tests: data["tests"]}
      end

      @tag :conformance
      test "load test cases", %{tests: tests} do
        assert is_list(tests), "Expected tests to be a list"
        assert length(tests) > 0, "Expected at least one test case"
      end

      for {test_case, index} <- Enum.with_index(Jason.decode!(File.read!(file))["tests"]) do
        test_name = test_case["name"] || "test_#{index}"

        @tag :conformance
        test "#{test_name}", %{tests: tests} do
          test_case = Enum.at(tests, unquote(index))
          selector = test_case["selector"]
          doc = test_case["document"]
          invalid? = Map.get(test_case, "invalid_selector", false)

          try do
            case JsonPath.tokenize(selector) do
              {:error, reason} ->
                unless invalid? do
                  flunk(
                    "Expected selector #{inspect(selector)} to be valid, but tokenizer failed with reason: #{inspect(reason)}"
                  )
                end

              {:ok, tokens, _line} ->
                case JsonPath.parse(tokens) do
                  {:error, reason} ->
                    unless invalid? do
                      flunk(
                        "Expected selector #{inspect(selector)} to be valid, but parser failed with reason: #{inspect(reason)}"
                      )
                    end

                  {:ok, ast} ->
                    if invalid? do
                      flunk(
                        "Expected invalid selector #{inspect(selector)}, but parser succeeded"
                      )
                    else
                      case JsonPath.evaluate(ast, doc) do
                        {:error, reason} ->
                          flunk(
                            "Evaluation error for selector #{inspect(selector)}: #{inspect(reason)}"
                          )

                        results when is_list(results) ->
                          result_values = Enum.map(results, fn {_path, val} -> val end)
                          result_paths = Enum.map(results, fn {path, _val} -> path end)

                          cond do
                            test_case["result"] ->
                              # Single result expectation
                              unless result_values == test_case["result"] do
                                flunk(
                                  "Selector #{inspect(selector)} produced #{inspect(result_values)} but expected #{inspect(test_case["result"])}"
                                )
                              end

                              if test_case["result_paths"] do
                                unless result_paths == test_case["result_paths"] do
                                  flunk(
                                    "Selector #{inspect(selector)} produced paths #{inspect(result_paths)} but expected #{inspect(test_case["result_paths"])}"
                                  )
                                end
                              end

                            test_case["results"] ->
                              # Multiple possible orderings
                              unless result_values in test_case["results"] do
                                flunk(
                                  "Selector #{inspect(selector)} produced #{inspect(result_values)} but expected one of #{inspect(test_case["results"])}"
                                )
                              end

                              if test_case["results_paths"] do
                                unless result_paths in test_case["results_paths"] do
                                  flunk(
                                    "Selector #{inspect(selector)} produced paths #{inspect(result_paths)} but expected one of #{inspect(test_case["results_paths"])}"
                                  )
                                end
                              end

                            true ->
                              flunk("No result field in test case: #{inspect(test_case)}")
                          end
                      end
                    end
                end
            end
          rescue
            error ->
              unless invalid? do
                flunk(
                  "Expected selector #{inspect(selector)} to be valid, but got error: #{Exception.message(error)}"
                )
              end
          end
        end
      end
    end
  end
end
