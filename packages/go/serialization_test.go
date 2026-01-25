package kreuzberg

import (
	"encoding/json"
	"testing"
)

// TestExtractionConfigSerialization validates that ExtractionConfig serializes correctly.
func TestExtractionConfigSerialization(t *testing.T) {
	config := &ExtractionConfig{
		UseCache:                   true,
		EnableQualityProcessing:    true,
		ForceOcr:                   false,
	}

	// Serialize to JSON
	jsonBytes, err := json.Marshal(config)
	if err != nil {
		t.Fatalf("Failed to serialize config: %v", err)
	}

	// Validate that JSON is valid
	var parsed map[string]interface{}
	if err := json.Unmarshal(jsonBytes, &parsed); err != nil {
		t.Fatalf("Invalid JSON output: %v", err)
	}

	// Check for expected fields (Go uses PascalCase)
	expectedFields := []string{"UseCache", "EnableQualityProcessing", "ForceOcr"}
	for _, field := range expectedFields {
		if _, ok := parsed[field]; !ok {
			t.Errorf("Missing field '%s' in serialized output", field)
		}
	}
}

// TestExtractionConfigDeserializationMinimal validates minimal config deserialization.
func TestExtractionConfigDeserializationMinimal(t *testing.T) {
	config := &ExtractionConfig{}

	// Serialize
	jsonBytes, err := json.Marshal(config)
	if err != nil {
		t.Fatalf("Failed to serialize: %v", err)
	}

	// Deserialize
	var restored ExtractionConfig
	if err := json.Unmarshal(jsonBytes, &restored); err != nil {
		t.Fatalf("Failed to deserialize: %v", err)
	}

	// Validate
	if config.UseCache != restored.UseCache {
		t.Errorf("UseCache not preserved: %v != %v", config.UseCache, restored.UseCache)
	}
}

// TestExtractionConfigRoundTrip validates round-trip serialization.
func TestExtractionConfigRoundTrip(t *testing.T) {
	original := &ExtractionConfig{
		UseCache:                   true,
		EnableQualityProcessing:    false,
		ForceOcr:                   true,
	}

	// Serialize to JSON
	jsonBytes1, err := json.Marshal(original)
	if err != nil {
		t.Fatalf("Failed to serialize original: %v", err)
	}

	// Deserialize
	var restored ExtractionConfig
	if err := json.Unmarshal(jsonBytes1, &restored); err != nil {
		t.Fatalf("Failed to deserialize: %v", err)
	}

	// Serialize again
	jsonBytes2, err := json.Marshal(&restored)
	if err != nil {
		t.Fatalf("Failed to serialize restored: %v", err)
	}

	// JSON should be equivalent
	if string(jsonBytes1) != string(jsonBytes2) {
		t.Errorf("Round-trip serialization mismatch:\n%s\nvs\n%s", jsonBytes1, jsonBytes2)
	}
}

// TestExtractionConfigFieldConsistency validates that fields are consistently present.
func TestExtractionConfigFieldConsistency(t *testing.T) {
	configs := []*ExtractionConfig{
		{},
		{UseCache: true},
		{EnableQualityProcessing: false},
		{UseCache: true, EnableQualityProcessing: true, ForceOcr: false},
	}

	for i, config := range configs {
		jsonBytes, err := json.Marshal(config)
		if err != nil {
			t.Fatalf("Config %d: Failed to serialize: %v", i, err)
		}

		var parsed map[string]interface{}
		if err := json.Unmarshal(jsonBytes, &parsed); err != nil {
			t.Fatalf("Config %d: Invalid JSON: %v", i, err)
		}

		// All configs should have the same expected fields
		expectedFields := []string{"UseCache", "EnableQualityProcessing", "ForceOcr"}
		for _, field := range expectedFields {
			if _, ok := parsed[field]; !ok {
				t.Errorf("Config %d: Missing field '%s'", i, field)
			}
		}
	}
}

// TestExtractionConfigPrettyPrint validates pretty-printed JSON.
func TestExtractionConfigPrettyPrint(t *testing.T) {
	config := &ExtractionConfig{
		UseCache:                   true,
		EnableQualityProcessing:    false,
	}

	// Serialize with indentation
	jsonBytes, err := json.MarshalIndent(config, "", "  ")
	if err != nil {
		t.Fatalf("Failed to marshal with indent: %v", err)
	}

	// Should be valid JSON
	var parsed map[string]interface{}
	if err := json.Unmarshal(jsonBytes, &parsed); err != nil {
		t.Fatalf("Invalid pretty-printed JSON: %v", err)
	}
}
