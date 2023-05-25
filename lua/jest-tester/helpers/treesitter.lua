local M = {}

--- Returns a list-like table for all the parent nodes of a node
---@param node TSNode a tree-sitter node
---@return TSNode[] a list of tree-sitter nodes
M.get_all_parent_nodes = function(node)
  local result = {}
  local immediate_parent = node:parent() or nil
  if not immediate_parent then
    return result
  end
  table.insert(result, immediate_parent)
  local ancestors = M.get_all_parent_nodes(immediate_parent)
  for _, parent in ipairs(ancestors) do
    table.insert(result, parent)
  end
  return result
end

--- Retrieves the root treesitter node of the buffer given
---@param bufnr (integer|nil) A buffer number. Defaults to the current buffer
---@param filetype (string|nil) The filetype of the buffer you want to parse. Defaults to the buffer filetype
---@return TSNode The root node of the parsed buffer
M.get_buffer_root_node = function(bufnr, filetype)
  local parser = vim.treesitter.get_parser(bufnr, filetype, {})
  local tree = parser:parse()[1]
  return tree:root()
end

--- Creates a ancestor specific query string
---@param ancestor_name string The name fo the string in the test block/function
---@return string the raw `treesitter` query string
M.test_function_query_string = function(ancestor_name)
  return string.format(
    [[ 
      (call_expression
        function: [
          (identifier) @function-name
          (member_expression
            object: (identifier) @function-name
            _*)
        ]
        arguments: (arguments
          (string
            (string_fragment) @test-name
            (#eq? @test-name "%s")
          ) 
          (arrow_function ; should probably change this to something general
            (statement_block
              (expression_statement
                (call_expression
                  function: [
                    (identifier) @function-call
                    (member_expression
                      object: (identifier) @function-call
                      _*)
                  ]
                  arguments: (arguments
                    (string
                      (string_fragment) @string-arg
                    ) 
                  ) @function-args
                  (#match? @function-call "(it)|(test)")
                )
              )
            )
          )
        ) @function-params
        (#eq? @function-name "describe")
      )
    ]],
    ancestor_name
  )
end

return M
