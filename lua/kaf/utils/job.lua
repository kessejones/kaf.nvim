local Job = {}
Job.__index = Job

function Job.new(cmd, opts)
    local obj = setmetatable({
        cmd = cmd,
        opts = opts or {},
    }, Job)

    return obj
end

function Job:run_sync(input)
    local output = {}
    local exit_code = 0

    local opts_extended = vim.tbl_deep_extend("force", self.opts, {
        on_stdout = function(_, data, _)
            for _, line in ipairs(data) do
                table.insert(output, line)
            end
        end,
        on_exit = function(_, code)
            exit_code = code
        end,
        stdout_buffered = true,
    })

    local jid = vim.fn.jobstart(self.cmd, opts_extended)
    if input ~= nil and #input > 0 then
        vim.fn.chansend(jid, input)
        vim.fn.chanclose(jid, "stdin")
    end
    vim.fn.jobwait({ jid })

    return { success = exit_code == 0, lines = output }
end

return Job
