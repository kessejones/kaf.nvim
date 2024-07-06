local M = {}

---@class kaf.KafOpts
---@field public type_formatter kaf.TypeFormatter?
---@field public type_detector kaf.TypeDetector?
---@field public integrations kaf.Integrations?
---@field public confirm_on_produce_message boolean?
---@field private kafka table? Not used for now

---@alias kaf.TypeFormatterHandler fun(text: string): string
---@alias kaf.TypeFormatter table<string, kaf.TypeFormatterHandler>

---@alias kaf.TypeDetectorHandler fun(text: string): boolean
---@alias kaf.TypeDetector table<string, kaf.TypeDetectorHandler>

---@class kaf.Integrations
---@field public fidget boolean?
---@field private telescope boolean? Currently the only UI for this plugin
---
---@class kaf.ProduceOpts
---@field public key string?
---@field public prompt_key boolean
---@field public value string?
---@field public value_from_buffer boolean

---@class Topic
---@field public name string
---@field public partitions integer

---@class Message
---@field public key string?
---@field public partition integer
---@field public offset integer
---@field public value string

---@class Notification
---@field public title string?
---@field public message string
---@field public percentage integer?

return M
