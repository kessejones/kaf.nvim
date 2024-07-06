# API

- [produce(opts)](#produce)
- [setup(opts)](#setupopts)

## produce(opts)

`produce(opts)` \
Produces a message in a kafka topic

| Param |                          | Type                   | Desc                                                                  |
| ----- | ------------------------ | ---------------------- | --------------------------------------------------------------------- |
| opts  |                          | `kaf.ProduceOpts\|nil` |                                                                       |
|       | `value_from_buffer\|nil` | `boolean\|nil`         | Send buffer as value to kafka message                                 |
|       | `value\|nil`             | `string\|nil`          | Value used for message (will be ignored if value_from_buffer is true) |
|       | `key\|nil`               | `string\|nil`          | Key used for message                                                  |
|       | `prompt_key\|nil`        | `boolean\|nil`         | Open a prompt for input the key                                       |

## setup(opts)

`setup(opts)` \
Initialize kaf

| Param | Type               | Desc |
| ----- | ------------------ | ---- |
| opts  | `kaf.KafOpts\|nil` |      |

# Integrations

## Telescope

- [clients(opts)](#clients)
- [topics(opts)](#topics)
- [messages(opts)](#messages)

### clients(opts)

`integrations.telescope.clients(opts)` \
List manageble clients

| Param |     | Type                            | Desc |
| ----- | --- | ------------------------------- | ---- |
| opts  |     | `kaf.TelescopeClientsOpts\|nil` |      |

### topics(opts)

`integrations.telescope.topics(opts)` \
List topics from selected client

| Param |     | Type                           | Desc |
| ----- | --- | ------------------------------ | ---- |
| opts  |     | `kaf.TelescopeTopicsOpts\|nil` |      |

### messages(opts)

`integrations.telescope.messages(opts)` \
List messages from selected client and topic

| Param |     | Type                             | Desc |
| ----- | --- | -------------------------------- | ---- |
| opts  |     | `kaf.TelescopeMessagesOpts\|nil` |      |
