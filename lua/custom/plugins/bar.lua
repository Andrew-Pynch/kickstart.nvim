-- Beyond All Reason (BAR) and RecoilEngine contribution settings.
--
-- Both projects ask outside contributors not to let AI write their code
-- (AI_POLICY.md in each repo). AI may answer questions and review your work,
-- so only inline AI completion is paused, and only inside those checkouts.
--
-- Format-on-save is off in those checkouts too: BAR CI checks formatting on
-- the lines a PR changes, and RecoilEngine has no .clang-format, so a
-- whole-file format on save rewrites lines you never touched. Format a
-- selection by hand with <leader>ff instead.

-- A BAR game checkout (BAR.sdd): modinfo.lua next to .emmyrc.json.
local function bar_root(buf)
  local root = vim.fs.root(buf, 'modinfo.lua')
  if root and vim.uv.fs_stat(root .. '/.emmyrc.json') then
    return root
  end
end

-- A RecoilEngine checkout: docker-build-v2/ next to rts/.
local function recoil_root(buf)
  local root = vim.fs.root(buf, 'docker-build-v2')
  if root and vim.uv.fs_stat(root .. '/rts') then
    return root
  end
end

local function contribution_root(buf)
  return bar_root(buf) or recoil_root(buf)
end

local group = vim.api.nvim_create_augroup('bar-contribution', { clear = true })

-- BAR configures EmmyLua (.emmyrc.json, the CI type check) and lists the
-- sumneko lua-language-server as an unwanted extension, so BAR files get
-- emmylua_ls and every other Lua file keeps lua_ls.
local warned_missing_emmylua = false
vim.lsp.config('emmylua_ls', {
  root_dir = function(buf, on_dir)
    local root = bar_root(buf)
    if not root then
      return
    end
    if vim.fn.executable 'emmylua_ls' == 0 then
      if not warned_missing_emmylua then
        warned_missing_emmylua = true
        vim.notify('BAR: emmylua_ls is not on PATH, so BAR Lua files have no language server', vim.log.levels.WARN)
      end
      return
    end
    on_dir(root)
  end,
})
vim.lsp.enable 'emmylua_ls'

vim.lsp.config('lua_ls', {
  root_dir = function(buf, on_dir)
    if bar_root(buf) then
      return
    end
    on_dir(vim.fs.root(buf, vim.lsp.config.lua_ls.root_markers or { '.git' }))
  end,
})

-- Supermaven checks vim.g.SUPERMAVEN_DISABLED on BufEnter. This autocmd is
-- created while lazy.nvim reads the plugin specs, before Supermaven creates
-- its own, so it runs first and Supermaven stops or starts to match.
local paused_supermaven = false
vim.api.nvim_create_autocmd('BufEnter', {
  group = group,
  callback = function(args)
    -- Pickers, file trees and unnamed scratch buffers keep the current state.
    if vim.bo[args.buf].buftype ~= '' or vim.api.nvim_buf_get_name(args.buf) == '' then
      return
    end
    if contribution_root(args.buf) then
      if vim.g.SUPERMAVEN_DISABLED ~= 1 then
        vim.g.SUPERMAVEN_DISABLED = 1
        paused_supermaven = true
      end
    elseif paused_supermaven then
      vim.g.SUPERMAVEN_DISABLED = 0
      paused_supermaven = false
    end
  end,
})

-- RecoilEngine is C++. The parsers install on first use; highlighting starts
-- the next time a file of that type opens.
vim.api.nvim_create_autocmd('FileType', {
  group = group,
  pattern = { 'cpp', 'cmake' },
  callback = function(args)
    if not pcall(vim.treesitter.start, args.buf) then
      require('nvim-treesitter').install { 'cpp', 'cmake' }
    end
  end,
})

return {
  {
    'stevearc/conform.nvim',
    opts = function(_, opts)
      local on_save = opts.format_on_save
      opts.format_on_save = function(buf)
        if contribution_root(buf) then
          return nil
        end
        if type(on_save) == 'function' then
          return on_save(buf)
        end
        return on_save
      end
    end,
  },
}
