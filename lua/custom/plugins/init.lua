-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  {
    "greggh/claude-code.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim", -- Required for git operations
    },
    config = function()
      require("claude-code").setup({
        -- Keep the default <C-,> for quick toggle from anywhere
        keymaps = {
          toggle = {
            normal = "<C-,>",     -- Keep default
            terminal = "<C-,>",   -- Keep default
          },
          -- Leader-based keymaps using 'a' for AI/Assistant
          variants = {
            -- Primary claude actions
            continue = "<leader>ac",  -- Continue conversation
            resume = "<leader>ar",    -- Resume with picker
            verbose = "<leader>av",   -- Verbose mode
          },
        },
      })
      
      -- Additional custom keymaps for better integration
      local map = vim.keymap.set
      
      -- Test bindings to check if plugin is working
      map('n', '<leader>zc', '<cmd>ClaudeCode<CR>', { desc = 'Test Claude Toggle' })
      map('n', '<F9>', '<cmd>ClaudeCode<CR>', { desc = 'Claude F9 Test' })
      map('n', '<leader>9', '<cmd>ClaudeCode<CR>', { desc = 'Claude 9 Test' })
      
      -- Terminal-specific escapes
      map('t', '<leader>a', '<C-\\><C-n><cmd>ClaudeCode<CR>', { desc = 'Toggle Claude from terminal' })
      map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Escape terminal mode' })
    end
  }
}
