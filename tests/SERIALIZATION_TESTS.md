# Cross-Language Serialization Test Suite

This document describes the comprehensive serialization test suite that validates JSON consistency across all Kreuzberg language bindings.

## Overview

The cross-language serialization test suite ensures that:

1. **ExtractionConfig** serializes correctly in each language binding
2. **Field consistency** across all languages (handling naming conventions)
3. **Round-trip serialization** preserves all data
4. **JSON equivalence** across different language implementations
5. **Edge cases** like null values and nested structures are handled correctly

## File Structure

```
tests/
├── cross_language_serialization_test.py      # Main test suite (Python)
└── SERIALIZATION_TESTS.md                    # This file

Rust Integration Tests:
crates/kreuzberg/tests/
└── serialization_integration.rs              # Rust serialization tests

Language-Specific Tests:
packages/typescript/tests/
├── serialization.spec.ts                     # TypeScript serialization tests
packages/ruby/spec/
├── serialization_spec.rb                     # Ruby serialization tests
packages/go/
├── serialization_test.go                     # Go serialization tests

Rust Helper Binary:
src/bin/
└── extraction_config_json_helper.rs          # JSON serialization helper
```

## Test Categories

### 1. Rust Serialization Tests

**File**: `crates/kreuzberg/tests/serialization_integration.rs`

Tests that validate Rust's native serialization capabilities:

- `test_extraction_config_minimal_serialization()` - Serializes default config
- `test_extraction_config_serialization_round_trip()` - Round-trip preservation
- `test_extraction_config_nested_serialization()` - Nested structure handling
- `test_extraction_config_json_format()` - Valid JSON format
- `test_extraction_config_pretty_print()` - Pretty-printed output
- `test_extraction_config_field_consistency()` - Field presence consistency

**Run with**:
```bash
cargo test --test serialization_integration
```

### 2. Python Serialization Tests

**File**: `tests/cross_language_serialization_test.py`

Tests that validate Python binding serialization:

- `test_python_extraction_config_serialization()` - Python binding serialization
- `test_serialization_round_trip()` - Round-trip for Python configs
- `test_all_expected_fields_present()` - Field validation
- `test_null_and_empty_handling()` - Edge case handling

**Run with**:
```bash
pytest tests/cross_language_serialization_test.py::test_python_extraction_config_serialization -v
```

### 3. TypeScript Serialization Tests

**File**: `packages/typescript/tests/serialization.spec.ts`

Tests that validate TypeScript/Node.js binding serialization:

- `should serialize minimal config to JSON` - Basic serialization
- `should serialize config with all fields` - Full config
- `should preserve field values after serialization` - Data preservation
- `should handle serialization round-trip` - Round-trip consistency
- `should use camelCase field names` - TypeScript naming convention
- `should serialize with nested ocr config` - Nested structure handling

**Run with**:
```bash
cd packages/typescript
npm test -- serialization.spec.ts
```

### 4. Ruby Serialization Tests

**File**: `packages/ruby/spec/serialization_spec.rb`

Tests that validate Ruby binding serialization:

- `#to_h` - Hash serialization
- `#to_json` - JSON serialization
- `round-trip serialization` - Preservation after deserialization
- `field consistency` - Required fields present
- `immutability` - No side effects during serialization

**Run with**:
```bash
cd packages/ruby
bundle exec rspec spec/serialization_spec.rb
```

### 5. Go Serialization Tests

**File**: `packages/go/serialization_test.go`

Tests that validate Go binding serialization:

- `TestExtractionConfigSerialization()` - Basic serialization
- `TestExtractionConfigDeserializationMinimal()` - Deserialization
- `TestExtractionConfigRoundTrip()` - Round-trip preservation
- `TestExtractionConfigFieldConsistency()` - Field consistency
- `TestExtractionConfigPrettyPrint()` - Formatted output

**Run with**:
```bash
cd packages/go
go test -v ./... -run TestExtractionConfigSerialization
```

## Field Naming Conventions

The test suite validates that field names are correctly mapped according to each language's conventions:

| Canonical (Rust) | Python | TypeScript | Ruby | Go | Java | PHP | C# | Elixir |
|---|---|---|---|---|---|---|---|---|
| `use_cache` | `use_cache` | `useCache` | `use_cache` | `UseCache` | `useCache` | `use_cache` | `UseCache` | `use_cache` |
| `enable_quality_processing` | `enable_quality_processing` | `enableQualityProcessing` | `enable_quality_processing` | `EnableQualityProcessing` | `enableQualityProcessing` | `enable_quality_processing` | `EnableQualityProcessing` | `enable_quality_processing` |
| `force_ocr` | `force_ocr` | `forceOcr` | `force_ocr` | `ForceOcr` | `forceOcr` | `force_ocr` | `ForceOcr` | `force_ocr` |

## Test Fixtures

The test suite uses multiple fixtures to validate serialization under different conditions:

### 1. Minimal Config
- Only default values
- Validates basic field presence
- Example: `{}`

### 2. With OCR
- Includes OCR configuration
- Validates nested structure handling
- Example: `{"ocr": {"backend": "tesseract", "language": "eng"}}`

### 3. With Chunking
- Includes chunking configuration
- Tests complex nested objects
- Example: `{"chunking": {"strategy": "semantic", "max_chunk_size": 1024}}`

### 4. Full Config
- All common fields populated
- Comprehensive feature coverage
- Example: Multiple features enabled

## Cross-Language Validation

### Parity Tests

The test suite includes high-level parity tests that:

1. Create configs in Python and other available languages
2. Serialize each to JSON
3. Compare JSON structures for equivalence
4. Report any field or naming mismatches

### Round-Trip Tests

All language bindings are tested for round-trip serialization:

```
Config Object -> Serialize to JSON -> Parse JSON -> Create Config -> Serialize again
```

The resulting JSON should be equivalent to the original.

### Field Presence Tests

Each language binding must include all required fields:

- `use_cache` / `useCache` (language-dependent naming)
- `enable_quality_processing` / `enableQualityProcessing`
- `force_ocr` / `forceOcr`

## Edge Cases Tested

### Null/None Handling
- Optional fields set to null/None
- Deserialization with missing optional fields
- Serialization of incomplete configs

### Empty Collections
- Empty arrays in chunking or image configs
- Empty nested objects
- Default values for unspecified fields

### Special Characters
- Unicode in language names
- Path-like strings in configuration
- Escaped characters in JSON

## Rust Helper Binary

The `extraction_config_json_helper` binary enables cross-language testing by serializing ExtractionConfig to JSON.

### Building
```bash
cargo build --bin extraction_config_json_helper --release
```

### Usage
```bash
# From file
extraction_config_json_helper < config.json

# From command-line argument
extraction_config_json_helper '{"use_cache": true}'
```

### Output Format
Pretty-printed JSON with indentation:
```json
{
  "use_cache": true,
  "enable_quality_processing": true,
  "force_ocr": false
}
```

## Running All Tests

### Python (Main Test Suite)
```bash
pytest tests/cross_language_serialization_test.py -v
```

### Rust
```bash
cargo test --test serialization_integration
```

### TypeScript
```bash
cd packages/typescript && npm test -- serialization.spec.ts
```

### Ruby
```bash
cd packages/ruby && bundle exec rspec spec/serialization_spec.rb
```

### Go
```bash
cd packages/go && go test -v ./... -run Serialization
```

## CI/CD Integration

The test suite is designed to run in CI/CD pipelines:

### GitHub Actions
Add to workflow:
```yaml
- name: Run Serialization Tests
  run: pytest tests/cross_language_serialization_test.py -v

- name: Run Language-Specific Tests
  run: |
    cd packages/typescript && npm test -- serialization.spec.ts
    cd ../ruby && bundle exec rspec spec/serialization_spec.rb
```

### Local Development
```bash
# Run all tests
task test

# Run only serialization tests
task test -- tests/cross_language_serialization_test.py
```

## Expected Test Results

All tests should pass with:

1. **Rust serialization**: Direct JSON output with all fields present
2. **Python serialization**: Config objects serialize/deserialize correctly
3. **TypeScript serialization**: camelCase JSON with proper nesting
4. **Ruby serialization**: snake_case JSON with proper nesting
5. **Go serialization**: PascalCase JSON with proper structure
6. **Cross-language parity**: Equivalent JSON structures accounting for naming conventions

## Troubleshooting

### Test Failures

#### "Rust helper binary not built"
```bash
cargo build --bin extraction_config_json_helper --release
```

#### "kreuzberg Python binding not installed"
```bash
cd packages/python
pip install -e .
```

#### "npm not available"
Install Node.js:
```bash
# macOS
brew install node

# Linux
sudo apt-get install nodejs npm
```

#### "Ruby/bundle not available"
```bash
cd packages/ruby
bundle install
```

#### "Go tests failing"
Ensure ExtractionConfig struct has JSON tags:
```go
type ExtractionConfig struct {
    UseCache bool `json:"use_cache"`
    // ...
}
```

## Adding New Tests

To add a new serialization test:

1. **Create test fixture** in `EXTRACTION_CONFIG_FIXTURES`
2. **Add Python test** in `test_python_extraction_config_serialization()`
3. **Add language-specific test** in respective language directory
4. **Update naming mapping** in `test_field_name_mapping()`
5. **Add to parametrized test** with `@pytest.mark.parametrize`

Example:
```python
TestFixture(
    name="my_feature",
    expected_fields={"use_cache", "my_new_field"},
    config_dict={"my_new_field": "value"},
)
```

## Performance Considerations

The test suite includes:

- **Lazy fixture evaluation**: Language bindings not installed are skipped
- **Timeout protection**: All subprocess calls have 30-60 second timeouts
- **Error recovery**: Test failures don't block other language tests
- **Minimal dependencies**: Uses only standard library and pytest

## Maintenance

### Regular Updates

- **Monthly**: Update field mappings as API evolves
- **Per release**: Add new config fields to fixtures
- **As needed**: Fix skipped tests when bindings become available

### Documentation

Keep this file updated when:

- Adding new configuration fields
- Changing field naming conventions
- Adding new language bindings
- Updating test fixtures or strategies

## Related Documentation

- API Parity Rule: See `.ai-rulez/rules/api-reference-parity-across-bindings.md`
- Cross-Ecosystem Versioning: See `.ai-rulez/rules/cross-ecosystem-version-synchronization.md`
- Language Binding Standards: See `.ai-rulez/domains/*/rules/`
