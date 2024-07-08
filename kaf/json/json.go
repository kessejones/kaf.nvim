package json

import (
	"bytes"
	"encoding/json"
	"strings"
)

func Format(jsonData []byte, indent int) ([]string, error) {
	var buffer bytes.Buffer
	indentValue := strings.Repeat(" ", indent)

	if err := json.Indent(&buffer, jsonData, "", indentValue); err != nil {
		return nil, err
	}

	lines := strings.Split(buffer.String(), "\n")
	return lines, nil
}
