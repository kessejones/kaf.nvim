package client

import (
	"context"
	"fmt"

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

	topics := make([]Topic, len(topicsInternal))
	index := 0
	for _, detail := range topicsInternal {
		topic := Topic{
			Name:       detail.Topic,
			Partitions: len(detail.Partitions),
		}

		topics[index] = topic
		index++
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

	listedStartOffsets, err := admin.ListStartOffsets(ctx, topic)
	if err != nil {
		return nil, err
	}

	listedEndOffsets, err := admin.ListEndOffsets(ctx, topic)
	if err != nil {
		return nil, err
	}

	if len(listedEndOffsets) != len(listedStartOffsets) {
		return nil, fmt.Errorf("end_offsets and start_offsets have different length")
	}

	result := make(map[int32]PartitionMetadataOffset, len(listedStartOffsets[topic]))
	for partition, detailsStart := range listedStartOffsets[topic] {
		detailsEnd, ok := listedEndOffsets[topic][partition]
		if !ok {
			return nil, fmt.Errorf("end offset not found for topic '%s' and partition '%d'", topic, partition)
		}

		result[partition] = PartitionMetadataOffset{
			Id:          partition,
			StartOffset: detailsStart.Offset,
			EndOffset:   detailsEnd.Offset,
		}
	}

	return result, nil
}
