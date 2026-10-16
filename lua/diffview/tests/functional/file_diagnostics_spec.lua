local api = vim.api
local File = require("diffview.vcs.file").File
local GitRev = require("diffview.vcs.adapters.git.rev").GitRev
local RevType = require("diffview.vcs.rev").RevType

describe("local file diagnostics on detach", function()
  local file
  local bufnr

  before_each(function()
    bufnr = api.nvim_create_buf(false, true)
    file = File({
      adapter = { ctx = { toplevel = vim.uv.cwd() } },
      path = "diagnostics.txt",
      kind = "working",
      rev = GitRev(RevType.LOCAL),
    })
    file.bufnr = bufnr
    file:attach_buffer(true, { disable_diagnostics = true })
    assert.is_not_nil(File.attached[bufnr])
    assert.is_false(vim.diagnostic.is_enabled({ bufnr = bufnr }))
  end)

  after_each(function()
    File.attached[bufnr] = nil
    if api.nvim_buf_is_valid(bufnr) then
      api.nvim_buf_delete(bufnr, { force = true })
    end
  end)

  for _, method in ipairs({ "detach_buffer", "destroy" }) do
    it("cleans up a deleted buffer on " .. method, function()
      api.nvim_buf_delete(bufnr, { force = true })
      assert.is_false(api.nvim_buf_is_valid(bufnr))

      assert.has_no.errors(function()
        file[method](file)
      end)
      assert.is_nil(File.attached[bufnr])
    end)
  end

  it("restores diagnostics for a valid buffer", function()
    file:detach_buffer()

    assert.is_true(vim.diagnostic.is_enabled({ bufnr = bufnr }))
    assert.is_nil(File.attached[bufnr])
  end)
end)
