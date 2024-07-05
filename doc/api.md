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
