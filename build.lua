local has_go = vim.fn.executable("go")
assert(has_go, "Unable to install kaf.nvim: required 'go' to build the extension")

local artifact_file = require("kaf.utils").sourced_filepath()
local kaf_root = vim.fn.fnamemodify(artifact_file, ":p:h")
local kaf_go = kaf_root .. "/kaf"

local job_dependencies = vim.fn.jobstart({ "go", "get", "." }, {
    cwd = kaf_go,
    on_exit = function(_, code, _)
        if code ~= 0 then
            error("kaf build failed")
        end
    end,
})

vim.fn.jobwait({ job_dependencies }, 10000)

local job_build = vim.fn.jobstart({ "go", "build", "-o", "kaf" }, {
    cwd = kaf_go,
    on_exit = function(_, code, _)
        if code ~= 0 then
            error("kaf build failed")
        end
    end,
})

vim.fn.jobwait({ job_build }, 10000)
