package handlers

import "github.com/kessejones/kaf.nvim/client"

type ProduceMessageRequest struct {
	Opts *struct {
		Brokers []string `msgpack:"brokers"`
		Key     string   `msgpack:"key"`
		Value   string   `msgpack:"value"`
		Topic   string   `msgpack:"topic"`
	} `msgpack:",array"`
}

type MessagesRequest struct {
	Opts *struct {
		Brokers []string `msgpack:"brokers"`
		Topic   string   `msgpack:"topic"`
	} `msgpack:",array"`
}

func Produce(request *ProduceMessageRequest) error {
	return client.Produce(
		request.Opts.Brokers,
		request.Opts.Topic,
		request.Opts.Key,
		request.Opts.Value,
	)
}

func GetMessages(request *MessagesRequest) ([]client.Message, error) {
	return client.GetMessages(request.Opts.Brokers, request.Opts.Topic)
}
