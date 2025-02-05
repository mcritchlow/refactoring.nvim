local config = require("refactoring.config")
local Pipeline = require("refactoring.pipeline")
local Point = require("refactoring.point")
local refactor_setup = require("refactoring.tasks.refactor_setup")
local post_refactor = require("refactoring.tasks.post_refactor")
local lsp_utils = require("refactoring.lsp_utils")
local Config = require("refactoring.config")

local function printDebug(bufnr, opts)
    return Pipeline
        :from_task(refactor_setup(bufnr, Config.get_config()))
        :add_task(function(refactor)
            local point = Point:from_cursor(refactor.bufnr)
            local region = point:to_region()
            local node = point:to_ts_node(refactor.ts:get_root())
            local debug_path = refactor.ts:get_debug_path(node)

            local path = {}
            for i = #debug_path, 1, -1 do
                table.insert(path, refactor.ts:to_string(debug_path[i]))
            end

            local code_gen = config.get_code_generation_for()
            if not code_gen then
                return false,
                    string.format("No code generator for %s", vim.bo[0].ft)
            end

            local debug_path_concat = table.concat(path, "#")
            local print_statement = code_gen.print(debug_path_concat)

            refactor.text_edits = {
                lsp_utils.insert_new_line_text(region, print_statement, opts),
            }

            return true, refactor
        end)
        :after(post_refactor)
        :run()
end

return printDebug
