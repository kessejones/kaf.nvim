package client

import (
	"context"

	"github.com/twmb/franz-go/pkg/kadm"
	"github.com/twmb/franz-go/pkg/kgo"
)

type Topic struct {
	Name       string `msgpack:"name"`
	Partitions int    `msgpack:"partitions"`
}

func CreateTopic(brokers []string, name string, partitions int) error {
	client, err := kgo.NewClient(kgo.SeedBrokers(brokers...))
	if err != nil {
		return err
	}
	admin := kadm.NewClient(client)
	defer admin.Close()
	defer client.Close()

	_, err = admin.CreateTopic(context.Background(), int32(partitions), -1, nil, name)
	if err != nil {
		return err
	}

	return nil
}

func GetTopics(brokers []string) ([]Topic, error) {
	topics := make([]Topic, 0)

	client, err := kgo.NewClient(kgo.SeedBrokers(brokers...))
	if err != nil {
		return nil, err
	}
	admin := kadm.NewClient(client)
	defer admin.Close()
	defer client.Close()

	topicsInternal, err := admin.ListTopics(context.Background())
	if err != nil {
		return nil, err
	}

	for _, detail := range topicsInternal {
		topic := Topic{
			Name:       detail.Topic,
			Partitions: detail.Partitions.NumReplicas(),
		}

		topics = append(topics, topic)
	}

	return topics, nil
}

func DeleteTopic(brokers []string, topic string) error {
	client, err := kgo.NewClient(kgo.SeedBrokers(brokers...))
	if err != nil {
		return err
	}
	admin := kadm.NewClient(client)
	defer admin.Close()
	defer client.Close()

	_, err = admin.DeleteTopic(context.Background(), topic)
	return err
}
