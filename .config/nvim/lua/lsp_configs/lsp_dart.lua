-- Set dart lsp using lspconfig
local lspconfig = require('lspconfig')

-- Set the path to the dart sdk
local dart_sdk_path = os.getenv('DART_SDK')

-- Set the path to the flutter sdk
local flutter_sdk_path = os.getenv('FLUTTER_SDK')

-- Configure the dart language server
lspconfig.dartls.setup {
  init_options = {
    closingLabels = true,
    flutterOutline = true,
    onlyAnalyzeProjectsWithOpenFiles = true,
    outline = true,
    suggestFromUnimportedLibraries = true,
  },
  filetypes = { 'dart' },
  root_dir = lspconfig.util.root_pattern('pubspec.yaml', '.git'),
  settings = {
    dart = {
      analysisExcludedFolders = { 'build', '.dart_tool' },
      completeFunctionCalls = true,
      enableSdkFormatter = true,
      flutterSdkPath = flutter_sdk_path,
      previewLspSetting = true,
      sdkPath = dart_sdk_path,
    },
  },
}
