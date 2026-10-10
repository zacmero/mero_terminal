return {
  {
    "3rd/image.nvim",
    enabled = vim.env.MERO_LITE ~= "1",
    version = false,
    build = false,
    opts = {
      rocks = {
        hererocks = false,
        enabled = false,
      },
    },
  },
}
