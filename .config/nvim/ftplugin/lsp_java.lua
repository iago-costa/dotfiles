local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
local workspace_dir = "/home/zen/workspaces/" .. project_name

local on_attach = require('lsp-zero.on_attach')
local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())

capabilities.workspace = {
    configuration = true,
    didChangeWatchedFiles = {
        dynamicRegistration = true
    },
    didChangeConfiguration = {
        dynamicRegistration = true
    }
}

local config = {
    flags = {
        allow_incremental_sync = true
    },
    -- O comando para invocar o lsp. Eu recomendo seguir o caminho abaixo, através do executável em python
    cmd = {
        'jdtls',

        -- Na pasta do jdtls terá algumas pastas com configurações específicas do OS. Indique este caminho de acordo com seu OS
        -- '-configuration', os.getenv('JDTLS_CONFIG'),

        -- Para cada projeto, o lsp cria uma pasta com um workspace. Aqui você irá indicar onde irão ficar essas pastas.
        '-data', workspace_dir
    },

    -- A raiz do seu projeto
    root_dir = require("jdtls.setup").find_root({ 'gradlew', '.git', 'mvnw' }),
    on_attach = on_attach,
    capabilities = capabilities,

    -- Outras configurações, recomendável repetir
    settings = {
        java = {
            signatureHelp = { enabled = true },
            contentProvider = { preferred = 'fernflower' },
            completion = {
                -- Se precisar adicionar uma classe para import estático
                favoriteStaticMembers = {
                    "org.hamcrest.MatcherAssert.assertThat",
                    "org.hamcrest.Matchers.*",
                    "org.hamcrest.CoreMatchers.*",
                    "org.junit.jupiter.api.Assertions.*",
                    "java.util.Objects.requireNonNull",
                    "java.util.Objects.requireNonNullElse",
                    "org.mockito.Mockito.*"
                },
                filteredTypes = {
                    "com.sun.*",
                    "io.micrometer.shaded.*",
                    "java.awt.*",
                    "jdk.*",
                    "sun.*",
                },
            },
            sources = {
                organizeImports = {
                    starThreshold = 9999,
                    staticStarThreshold = 9999,
                },
            },
            codeGeneration = {
                -- Instrução para geração de métodos populares
                toString = {
                    template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}"
                },
                hashCodeEquals = {
                    useJava7Objects = true,
                },
                useBlocks = true,
            },
            configuration = {

                -- Indique aqui as versões de java e as pastas onde se encontram
                runtimes = {
                    {
                        name = "OpenJDK-21",
                        path = os.getenv("JAVA_HOME"),
                        default = true
                    },
                }
            },
        },
    }
}


require('jdtls').start_or_attach(config)
