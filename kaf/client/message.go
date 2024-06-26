package client

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/pkg/math"
	"github.com/twmb/franz-go/pkg/kadm"
	"github.com/twmb/franz-go/pkg/kgo"
)

type Message struct {
	Partition uint64 `msgpack:"partition"`
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
	messages := make([]Message, 0)

	offsets, err := topicOffsets(brokers, topic)
	if err != nil {
		return nil, err
	}

	partitionOffsets := make(map[string]map[int32]kgo.Offset)

	messagesPartitionsCount := make(map[int32]int32, len(offsets))
	partitionOffsets[topic] = make(map[int32]kgo.Offset)
	hasOffsets := false
	for _, offset := range offsets {
		startAt := math.MaxInt64(offset.StartOffset, offset.EndOffset-10)
		totalConsume := offset.EndOffset - startAt

		if totalConsume <= 0 {
			continue
		}

		messagesPartitionsCount[offset.Id] = int32(totalConsume)
		partitionOffsets[topic][offset.Id] = kgo.NewOffset().At(startAt)

		hasOffsets = true
	}

	if !hasOffsets {
		return messages, nil
	}

	client, err := kgo.NewClient(
		kgo.SeedBrokers(brokers...),
		kgo.ConsumePartitions(partitionOffsets),
	)

	if err != nil {
		return nil, err
	}

	defer client.Close()
	ctx := context.Background()

	fetches := client.PollFetches(ctx)
	if errs := fetches.Errors(); len(errs) > 0 {
		panic(fmt.Sprint(errs))
	}

	fetches.EachPartition(func(p kgo.FetchTopicPartition) {
		count := int32(0)
		for _, record := range p.Records {
			message := Message{
				Key:    record.Key,
				Value:  record.Value,
				Offset: record.Offset,
				Time:   record.Timestamp.Format(time.DateTime),
			}

			messages = append(messages, message)
			if count >= messagesPartitionsCount[p.Partition] {
				break
			}
			count++
		}
	})

	return messages, nil
}

func topicOffsets(brokers []string, topic string) (map[int32]PartitionMetadataOffset, error) {
	client, err := kgo.NewClient(kgo.SeedBrokers(brokers...))
	if err != nil {
		return nil, err
	}
	admin := kadm.NewClient(client)
	defer admin.Close()
	defer client.Close()

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
