package client

import (
	"context"
	"fmt"
	"time"

	"github.com/twmb/franz-go/pkg/kgo"
)

const MessagesPerPartition = 10

type Message struct {
	Partition int32  `msgpack:"partition"`
	Offset    int64  `msgpack:"offset"`
	Key       []byte `msgpack:"key"`
	Value     []byte `msgpack:"value"`
	Time      string `msgpack:"time"`
}

type PartitionMetadataOffset struct {
	Id          int32
	StartOffset int64
	EndOffset   int64
}

func Produce(brokers []string, topic, key, value string) error {
	client, err := kgo.NewClient(
		kgo.SeedBrokers(brokers...),
		kgo.ConsumerGroup("kaf-neovim"),
		kgo.DefaultProduceTopic(topic),
	)
	if err != nil {
		return err
	}
	defer client.Close()

	ctx := context.Background()
	record := &kgo.Record{
		Topic: topic,
		Key:   []byte(key),
		Value: []byte(value),
	}

	return client.ProduceSync(ctx, record).FirstErr()
}

func GetMessages(brokers []string, topic string) ([]Message, error) {
	client, err := kgo.NewClient(
		kgo.SeedBrokers(brokers...),
	)
	if err != nil {
		return nil, err
	}

	defer client.Close()

	messages := make([]Message, 0)
	partitionOffsets := make(map[string]map[int32]kgo.Offset)
	partitionOffsets[topic] = make(map[int32]kgo.Offset)

	messagesPartitionsCount := make(map[int32]int32)
	partitions, err := TopicPartitions(client, topic)
	if err != nil {
		return nil, err
	}

	for _, partition := range partitions {
		partitionOffsets[topic][partition.Partition] = kgo.NewOffset().Relative(-MessagesPerPartition)
		messagesPartitionsCount[partition.Partition] = MessagesPerPartition
	}

	client.AddConsumePartitions(partitionOffsets)
	ctx := context.Background()
	for range partitions {
		fetches := client.PollFetches(ctx)
		if errs := fetches.Errors(); len(errs) > 0 {
			panic(fmt.Sprint(errs))
		}

		fetches.EachPartition(func(p kgo.FetchTopicPartition) {
			for _, record := range p.Records {
				message := Message{
					Partition: record.Partition,
					Key:       record.Key,
					Value:     record.Value,
					Offset:    record.Offset,
					Time:      record.Timestamp.Format(time.DateTime),
				}

				messages = append(messages, message)
			}
		})
	}

	return messages, nil
}
