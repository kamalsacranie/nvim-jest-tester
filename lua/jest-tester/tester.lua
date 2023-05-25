local q = require "vim.treesitter"
local ts_helpers = require "jest-tester.helpers.treesitter"
local tools = require "jest-tester.helpers.utils"

local Tester = {}

local query_string_factory =
  require "filetypes.javascript_core.jest_virt_text.query_string_factory"

--- Tester class method to ensure the filetype we are running our tests on is valid
function Tester:check_filetype()
  if not vim.list_contains(self.allowed_filetypes, self.filetype) then
    error(
      "Attempted to test a file which has not been specified in the confit. Currently the only filteypse configured for testing are:"
        .. vim.json.encode(self.allowed_filetypes)
    )
  end
end

--- Tester class method to ensure that the filetype strings we specify match
function Tester:check_file_string()
  local filename_matchers = vim.tbl_map(vim.regex, self.filename_matches)
  local filename_matches = vim.tbl_map(function(filename_matcher)
    return filename_matcher:match_str(self.file_name_no_ext)
  end, filename_matchers)
  if #filename_matches == 0 then
    error(
      "Attempted to test a test file which did not match any of the filename regex patterns. The current filename patterns are:"
        .. vim.json.encode(self.filename_matches)
    )
  end
end

function Tester._parse_jest_json(test_json_data)
  local result = vim.json.decode(test_json_data)
  return result and result.testResults[1].assertionResults
end

function Tester:process_test_data(test_json_data)
  self.test_data = Tester._parse_jest_json(test_json_data)
  Tester.process_tests(self)
end

function Tester:find_test_line(input)
  local closest_ancestor_name = input.ancestorTitles[#input.ancestorTitles]
  local query_string = query_string_factory(closest_ancestor_name)
  local query = vim.treesitter.query.parse(self.filetype, query_string)
  local root = ts_helpers.get_buffer_root_node(self.bufnr, self.filetype)

  for _, nodes in query:iter_matches(root, self.bufnr, 0, -1) do
    local immediate_describe_node = nodes[2]
    local test_arg = nodes[4]

    local test_parent_nodes =
      ts_helpers.get_all_parent_nodes(immediate_describe_node)
    local function_nodes = vim.tbl_filter(function(node)
      return node:type() == "call_expression"
    end, test_parent_nodes)
    local function_call_nodes = vim.tbl_map(function(node)
      return node:child(0)
    end, function_nodes)
    local describe_nodes = vim.tbl_filter(function(node)
      local node_text = q.get_node_text(node, self.bufnr)
      return node_text:match "^describe"
    end, function_call_nodes)
    local describe_string_nodes = vim.tbl_map(function(node)
      return node
        :next_sibling() -- arguments node parent
        :child(0) -- arguments node
        :next_sibling() -- first argument
        :child(0) -- opening bracket
        :next_sibling() -- argument 1 substring
    end, describe_nodes)
    local describe_strings = vim.tbl_map(function(node)
      return q.get_node_text(node, self.bufnr)
    end, describe_string_nodes)
    local ordered_describe_strings = tools.reverse_list_table(describe_strings)

    local test_string = q.get_node_text(test_arg, self.bufnr)
    local test_line_number = test_arg:range()
    -- if we match our test name and also all of it's title ancestors
    if
      test_string == input.title
      and table.concat(ordered_describe_strings)
        == table.concat(input.ancestorTitles)
    then
      return test_line_number
    end
  end
  return false
end

function Tester:build_test_result(result)
  local test_line_number = Tester.find_test_line(self, result)
  if test_line_number then
    local temp = {
      line_num = test_line_number,
      test_status = result.status,
      failure_narrative = result.failureMessages,
    }
    return temp
  end
end

function Tester:process_tests()
  if not self.test_data then
    return
  end
  local test_results = vim.tbl_map(function(data)
    return Tester.build_test_result(self, data)
  end, self.test_data)
  self.test_results = test_results
end

function Tester:new()
  local bufnr = vim.fn.bufnr()
  self.bufnr = bufnr
  self.file_path = vim.fn.expand "%:p"
  self.file_name_no_ext = vim.fn.expand "%:r"
  self.filetype = vim.filetype.match { buf = bufnr }
  self.allowed_filetypes = { "javascript", "typescript" }
  self.filename_matches = { [[.*\.test$]] }
  -- Run our checks to make sure we can run tests
  Tester.check_filetype(self)
  Tester.check_file_string(self)
  return self
end

return Tester
