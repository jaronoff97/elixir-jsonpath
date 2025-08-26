# JsonPath for Elixir

A **minimal JSONPath engine in Elixir** using **LEEX + YECC** generated modules.

This library supports querying nested maps and lists using JSONPath syntax.
It currently implements a **partial subset of [RFC 9535](https://www.rfc-editor.org/rfc/rfc9535.html)** and passes **400/702 compliance tests**.

---

## Features

- Child selector (`.`) and descendant selector (`..`)
- Wildcards (`*`) for maps and arrays
- Array slices and indices (`[0:2]`, `[-1]`)
- Unions (`[0,2]`)
- Basic filters (`[?@.price<20]`)
- Returns **paths and values** in evaluation
- Convenience `query/2` helper for automatic tokenize → parse → evaluate
- Works with **Elixir maps and lists**

> ⚠️ Partial implementation: not all RFC 9535 features are implemented yet.

---

## Installation

Add to your `mix.exs`:

\```elixir
def deps do
  [
    {:json_path, "~> 0.1.0"}
  ]
end
\```

Then fetch dependencies:

\```bash
mix deps.get
\```

---

## Usage

### Basic Queries

\```elixir
data = %{
  "store" => %{
    "book" => [
      %{"title" => "Elixir in Action", "price" => 15},
      %{"title" => "Programming Phoenix", "price" => 20}
    ],
    "bicycle" => %{"color" => "red", "price" => 100}
  }
}

# Get all book prices
JsonPath.query(data, "$.store.book[*].price")
# => [{"$['store']['book'][0]['price']", 15}, {"$['store']['book'][1]['price']", 20}]

# Get bicycle color
JsonPath.query(data, "$.store.bicycle.color")
# => [{"$['store']['bicycle']['color']", "red"}]
\```

---

### Advanced Queries

\```elixir
# Descendant selector
JsonPath.query(data, "$..price")
# => [{"$['store']['book'][0]['price']", 15}, {"$['store']['book'][1]['price']", 20}, {"$['store']['bicycle']['price']", 100}]

# Union selection
JsonPath.query(data, "$.store.book[0,1]")
# => [{"$['store']['book'][0]", ...}, {"$['store']['book'][1]", ...}]

# Array slice
JsonPath.query(data, "$.store.book[0:2]")
# => first two books

# Negative index
JsonPath.query(data, "$.store.book[-1]")
# => last book

# Filter with comparison
JsonPath.query(data, "$..book[?@.price<20]")
# => books with price < 20

# Logical filter (AND/OR)
JsonPath.query(data, "$..book[?@.price>10 && @.price<30]")
# => books with 10 < price < 30
\```

---

## Functions

### `JsonPath.query(data, path_string)`
Convenience function to **tokenize → parse → evaluate** in one call.

- **Parameters:**
  - `data` – Map or List to query
  - `path_string` – JSONPath string
- **Returns:**
  - List of `{path_string, value}` or `{:error, reason}`

### `JsonPath.tokenize(query)`
Tokenizes a JSONPath string using the lexer.
- **Returns:** `{:ok, tokens, line}` or `{:error, reason}`

### `JsonPath.parse(tokens)`
Parses a token list into an AST.
- **Returns:** `{:ok, ast}` or `{:error, reason}`

### `JsonPath.evaluate(ast, data)`
Evaluates a parsed AST against data.
- **Returns:** List of `{path_string, value}`

---

## Compliance & Coverage

- Partial **RFC 9535** implementation
- **Passing 400/702 JSONPath compliance tests**
- Work in progress for full RFC coverage

---

## Contributing

1. Fork the repository
2. Implement or improve features
3. Run tests: `mix test`
4. Submit a pull request

---

## License

Apache License 2.0 © Jacob Aronoff
