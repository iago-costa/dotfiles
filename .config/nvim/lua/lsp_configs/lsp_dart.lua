

-- Set dart lsp using lspconfig
local lspconfig = require('lspconfig')

-- Set the path to the dart analysis server
local dart_analysis_server_path = '/opt/dart-sdk/bin/snapshots/analysis_server.dart.snapshot'

-- Set the path to the dart sdk
local dart_sdk_path = '/opt/dart-sdk'

-- Set the path to the flutter sdk
local flutter_sdk_path = '/opt/flutter'

-- Configure the dart language server
lspconfig.dartls.setup {
  cmd = { dart_analysis_server_path, '--lsp' },
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
