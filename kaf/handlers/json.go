package handlers

import (
	"github.com/kessejones/kaf.nvim/json"
)

type JsonFormatRequest struct {
	Opts *struct {
		Value  string `msgpack:"value"`
		Indent int    `msgpack:"indent"`
	} `msgpack:",array"`
}

func JsonFormat(request *JsonFormatRequest) ([]string, error) {
	return json.Format([]byte(request.Opts.Value), request.Opts.Indent)
}
