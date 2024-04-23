local has_cargo = vim.fn.executable("cargo")
assert(has_cargo, "Unable to install kaf.nvim: required cargo to build the extension")

local artifact_file = require("plenary.debug_utils").sourced_filepath()
local kaf_root = vim.fn.fnamemodify(artifact_file, ":p:h")

local target_dir = kaf_root .. "/target"
local release_dir = target_dir .. "/release/"
local release_file = release_dir .. "libkaf.so"
local lib_path = kaf_root .. "/lib"

vim.fn.system({ "cargo", "build", "--release" })
vim.fn.mkdir(lib_path, "p")
vim.fn.rename(release_file, lib_path .. "/libkaf.so")
vim.fn.delete(target_dir, "rf")
