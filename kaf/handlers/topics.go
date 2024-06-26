package handlers

import "github.com/kessejones/kaf.nvim/client"

type TopicsRequest struct {
	Opts *struct {
		Brokers []string `msgpack:"brokers"`
	} `msgpack:",array"`
}

type CreateTopicRequest struct {
	Opts *struct {
		Brokers    []string `msgpack:"brokers"`
		Topic      string   `msgpack:"topic"`
		Partitions int      `msgpack:"partitions"`
	} `msgpack:",array"`
}

type DeleteTopicRequest struct {
	Opts *struct {
		Brokers []string `msgpack:"brokers"`
		Topic   string   `msgpack:"topic"`
	} `msgpack:",array"`
}

func CreateTopic(request *CreateTopicRequest) error {
	return client.CreateTopic(request.Opts.Brokers, request.Opts.Topic, request.Opts.Partitions)
}

func GetTopics(request *TopicsRequest) ([]client.Topic, error) {
	return client.GetTopics(request.Opts.Brokers)
}

func DeleteTopic(request *DeleteTopicRequest) error {
	return client.DeleteTopic(request.Opts.Brokers, request.Opts.Topic)
}
