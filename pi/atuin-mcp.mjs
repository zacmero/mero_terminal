export default function (pi) {
  pi.registerMcpServer("atuin", {
    command: "atuin",
    args: ["mcp"],
    exposure: "codemode",
    description: "Search, list, and read agent threads captured by Atuin.",
    // Keep shell history and output tools hidden in native Pi and pi-mcp-adapter.
    toolExposure: {
      atuin_history: "hidden",
      atuin_output: "hidden",
      atuin_output_search: "hidden",
    },
  });
}
