-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- WSL: no X/Wayland clipboard, so bridge "+ and "* to the Windows clipboard.
-- Pattern from :h clipboard-wsl.
if vim.fn.has("wsl") == 1 then
  local paste = 'powershell.exe -NoLogo -NoProfile -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))'
  vim.g.clipboard = {
    name = "WslClipboard",
    copy = { ["+"] = "clip.exe", ["*"] = "clip.exe" },
    paste = { ["+"] = paste, ["*"] = paste },
    cache_enabled = 0,
  }
end
