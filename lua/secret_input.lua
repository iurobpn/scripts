local SecretInput = Input:extend("SecretInput")

function SecretInput:init(popup_options, options)
  assert(
    not options.conceal_char or vim.api.nvim_strwidth(options.conceal_char) == 1,
    "conceal_char must be a single char"
  )

  popup_options.win_options = vim.tbl_deep_extend("force", popup_options.win_options or {}, {
    conceallevel = 2,
    concealcursor = "nvi",
  })

  SecretInput.super.init(self, popup_options, options)

  self._.conceal_char = type(options.conceal_char) == "nil" and "*" or options.conceal_char
end

function SecretInput:mount()
  SecretInput.super.mount(self)

  local conceal_char = self._.conceal_char
  local prompt_length = vim.api.nvim_strwidth(vim.fn.prompt_getprompt(self.bufnr))

  vim.api.nvim_buf_call(self.bufnr, function()
    vim.cmd(string.format(
      [[
        syn region SecretValue start=/^/ms=s+%s end=/$/ contains=SecretChar
        syn match SecretChar /./ contained conceal %s
      ]],
      prompt_length,
      conceal_char and "cchar=" .. (conceal_char or "*") or ""
    ))
  end)
end

-- conceal secret characters with `*`
local input = SecretInput(popup_options, options)

-- conceal secret characters with `x`
local input = SecretInput(popup_options, {
  conceal_char = "x",
  -- other input options
})

-- completely hide secret characters
local input = SecretInput(popup_options, {
  conceal_char = false,
  -- other input options
})

