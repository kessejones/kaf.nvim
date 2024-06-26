package main

import (
	"github.com/kessejones/kaf.nvim/handlers"
	"github.com/neovim/go-client/nvim/plugin"
)

func main() {
	plugin.Main(func(p *plugin.Plugin) error {
		p.HandleFunction(&plugin.FunctionOptions{Name: "KafTopics"}, handlers.GetTopics)
		p.HandleFunction(&plugin.FunctionOptions{Name: "KafMessages"}, handlers.GetMessages)
		p.HandleFunction(&plugin.FunctionOptions{Name: "KafProduce"}, handlers.Produce)
		p.HandleFunction(&plugin.FunctionOptions{Name: "KafCreateTopic"}, handlers.CreateTopic)
		p.HandleFunction(&plugin.FunctionOptions{Name: "KafDeleteTopic"}, handlers.DeleteTopic)

		return nil
	})
}
