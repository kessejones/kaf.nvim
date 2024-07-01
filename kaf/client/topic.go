package client

import (
	"context"
	"log"

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
			Partitions: len(detail.Partitions),
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

func TopicPartitions(client *kgo.Client, topic string) (kadm.PartitionDetails, error) {
	admin := kadm.NewClient(client)
	metadata, err := admin.Metadata(context.Background(), topic)
	if err != nil {
		return nil, err
	}
	return metadata.Topics[topic].Partitions, nil
}

func TopicPartitionsOffset(client *kgo.Client, topic string) (map[int32]PartitionMetadataOffset, error) {
	admin := kadm.NewClient(client)
	ctx := context.Background()

	endOffsets, err := admin.ListEndOffsets(ctx, topic)
	if err != nil {
		return nil, err
	}

	startOffsets, err := admin.ListStartOffsets(ctx, topic)
	if err != nil {
		return nil, err
	}

	if len(endOffsets) != len(startOffsets) {
		log.Panic("offsets are not equal")
	}

	result := make(map[int32]PartitionMetadataOffset, len(startOffsets))

	startOffsets.Each(func(o kadm.ListedOffset) {
		result[o.Partition] = PartitionMetadataOffset{
			Id:          o.Partition,
			StartOffset: o.Offset,
		}
	})

	endOffsets.Each(func(o kadm.ListedOffset) {
		item, ok := result[o.Partition]
		if ok {
			item.EndOffset = o.Offset
			result[o.Partition] = item
		}
	})

	return result, nil
}
