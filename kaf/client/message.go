package client

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/pkg/math"
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

	topicPartitionsOffset, err := TopicPartitionsOffset(client, topic)
	if err != nil {
		return nil, err
	}

	messagesPartitionsCount := make(map[int32]int32)
	partitionOffsets := make(map[string]map[int32]kgo.Offset)
	partitionOffsets[topic] = make(map[int32]kgo.Offset)

	totalMessages := 0
	for partition, offsetData := range topicPartitionsOffset {
		startAt := math.MaxInt64(offsetData.StartOffset, offsetData.EndOffset-MessagesPerPartition)
		totalToConsume := offsetData.EndOffset - startAt

		if totalToConsume <= 0 {
			continue
		}

		partitionOffsets[topic][partition] = kgo.NewOffset().At(startAt)
		messagesPartitionsCount[partition] = int32(totalToConsume)

		totalMessages = totalMessages + int(totalToConsume)
	}

	if totalMessages == 0 {
		return []Message{}, nil
	}

	client.AddConsumePartitions(partitionOffsets)
	ctx := context.Background()
	wg := sync.WaitGroup{}

	recordChan := make(chan *kgo.Record, len(messagesPartitionsCount))

	go func() {
		wg.Wait()
		close(recordChan)
	}()

	for range messagesPartitionsCount {
		wg.Add(1)

		go func() {
			defer wg.Done()

			fetches := client.PollFetches(ctx)
			if errs := fetches.Errors(); len(errs) > 0 {
				panic(fmt.Sprint(errs))
			}

			iter := fetches.RecordIter()
			for !iter.Done() {
				recordChan <- iter.Next()
			}
		}()
	}

	messages := make([]Message, 0)
	for record := range recordChan {
		message := Message{
			Partition: record.Partition,
			Key:       record.Key,
			Value:     record.Value,
			Offset:    record.Offset,
			Time:      record.Timestamp.Format(time.DateTime),
		}

		messages = append(messages, message)
	}

	return messages, nil
}
