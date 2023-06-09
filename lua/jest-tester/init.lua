local M = {}
M.default_config = {
  filetypes = { "javascript", "typescript" },
  filename_matches = { [[.*\.test$]] },
  status_codes = {
    passed = { " ✅ ", "RedrawDebugComposed" },
    failed = { " 💀 ", "RedrawDebugRecompose" },
    pending = { " 💤 ", "lualine_a_insert" },
  },
}
local instance_config = nil

local Tester = require "jest-tester.tester"
local testing_status_ns = vim.api.nvim_create_namespace "jest-test-status"
local test_result_ns = vim.api.nvim_create_namespace "jest-tests"

--- Jest tester setup
---@param user_config (table|nil) Optional configuration to override defaults
M.setup = function(user_config)
  instance_config =
    vim.tbl_deep_extend("force", M.default_config, user_config or {})
end

M.test = function()
  local tester = Tester.new(instance_config or M.default_config)
  vim.api.nvim_buf_clear_namespace(tester.bufnr, test_result_ns, 0, -1)
  vim.api.nvim_buf_set_extmark(tester.bufnr, testing_status_ns, 0, 0, {
    virt_text = { { " TESTING ", "RedrawDebugComposed" } },
    virt_text_pos = "right_align",
  })
  vim.fn.jobstart({
    "npx",
    "--node-options=--experimental-vm-modules",
    "jest",
    "--json",
    "--silent",
    tester.file_path,
  }, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      local test_data = data[1]
      local success, response = pcall(function()
        Tester.process_test_data(tester, test_data)
      end)
      if not success then
        print("your tests failed to run", response)
      end
      for _, result in ipairs(tester.test_results) do
        vim.api.nvim_buf_set_extmark(
          tester.bufnr,
          test_result_ns,
          result.line_num,
          0,
          {
            virt_text = { M.default_config.status_codes[result.test_status] },
          }
        )
      end
      vim.api.nvim_buf_clear_namespace(tester.bufnr, testing_status_ns, 0, -1)
    end,
  })
end

return M
