local Job = {}
Job.__index = Job

function Job.new(cmd, opts)
    local obj =  setmetatable({
        cmd = cmd,
        opts = opts or {},
    }, Job)

    return obj
end

function Job:run_sync()
    local output = {}

    local opts_extended = vim.tbl_deep_extend("force", self.opts, {
        on_stdout = function(_, data, _)
            for _, line in ipairs(data) do
                table.insert(output, line)
            end
        end,
        on_stderr = function(_, data, _)
            for _, line in ipairs(data) do
                table.insert(output, line)
            end
        end,
    })

    local jid = vim.fn.jobstart(self.cmd, opts_extended)
    vim.fn.jobwait({jid})

    return output
end

return Job
