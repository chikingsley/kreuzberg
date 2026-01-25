# Cross-Language Serialization Test Suite

## Summary

This test suite comprehensively validates JSON serialization consistency across all Kreuzberg language bindings (Python, TypeScript, Ruby, Go, Java, PHP, C#, Elixir, and WASM).

## Quick Start

### Run All Serialization Tests

```bash
# Python main test suite
pytest tests/cross_language_serialization_test.py -v

# Rust integration tests
cargo test --test serialization_integration

# Language-specific tests (if installed)
cd packages/typescript && npm test -- serialization.spec.ts
cd packages/ruby && bundle exec rspec spec/serialization_spec.rb
cd packages/go && go test -v ./... -run Serialization
```

### Build Rust Helper Binary

```bash
cargo build --bin extraction_config_json_helper --release
```

## Test Files Created

| File | Purpose | Status |
|------|---------|--------|
| `tests/cross_language_serialization_test.py` | Main Python test suite | ✅ Created |
| `crates/kreuzberg/tests/serialization_integration.rs` | Rust integration tests | ✅ Created |
| `packages/typescript/tests/serialization.spec.ts` | TypeScript tests | ✅ Created |
| `packages/ruby/spec/serialization_spec.rb` | Ruby tests | ✅ Created |
| `packages/go/serialization_test.go` | Go tests | ✅ Created |
| `packages/java/src/test/java/SerializationTest.java` | Java tests | ✅ Created |
| `packages/php/tests/SerializationTest.php` | PHP tests | ✅ Created |
| `packages/csharp/SerializationTest.cs` | C# tests | ✅ Created |
| `packages/elixir/test/serialization_test.exs` | Elixir tests | ✅ Created |
| `src/bin/extraction_config_json_helper.rs` | JSON serialization helper binary | ✅ Created |
| `tests/SERIALIZATION_TESTS.md` | Detailed documentation | ✅ Created |
| `tests/README_SERIALIZATION.md` | This file | ✅ Created |

## Key Features

### 1. Comprehensive Coverage
- Tests all language bindings (9 languages)
- Validates both serialization and deserialization
- Tests edge cases (null values, empty collections)
- Includes round-trip testing

### 2. Field Name Mapping
Validates that field names follow each language's conventions:
- Rust/Python/Ruby/PHP/Elixir: `snake_case`
- TypeScript/Java/JavaScript: `camelCase`
- Go/C#: `PascalCase`

### 3. Test Fixtures
Multiple test configurations:
- **Minimal**: Default values only
- **With OCR**: Nested OCR config
- **With Chunking**: Chunking configuration
- **Full**: All features enabled

### 4. Cross-Language Validation
- Compares JSON output across languages
- Accounts for naming convention differences
- Validates field consistency
- Tests equivalence despite format differences

## Test Structure

```
tests/
├── cross_language_serialization_test.py     # Main test suite
├── SERIALIZATION_TESTS.md                   # Detailed docs
└── README_SERIALIZATION.md                  # This file

Language-Specific Tests:
├── crates/kreuzberg/tests/serialization_integration.rs
├── packages/typescript/tests/serialization.spec.ts
├── packages/ruby/spec/serialization_spec.rb
├── packages/go/serialization_test.go
├── packages/java/src/test/java/SerializationTest.java
├── packages/php/tests/SerializationTest.php
├── packages/csharp/SerializationTest.cs
└── packages/elixir/test/serialization_test.exs

Helper Binary:
└── src/bin/extraction_config_json_helper.rs
```

## Running Tests

### By Language

**Rust**
```bash
cargo test --test serialization_integration
```

**Python**
```bash
pytest tests/cross_language_serialization_test.py -v
```

**TypeScript**
```bash
cd packages/typescript && npm test -- serialization.spec.ts
```

**Ruby**
```bash
cd packages/ruby && bundle exec rspec spec/serialization_spec.rb
```

**Go**
```bash
cd packages/go && go test -v ./... -run Serialization
```

**Java** (if Maven configured)
```bash
cd packages/java && mvn test -Dtest=SerializationTest
```

**PHP** (if PHPUnit configured)
```bash
cd packages/php && phpunit tests/SerializationTest.php
```

**C#** (if .NET SDK installed)
```bash
cd packages/csharp && dotnet test --filter SerializationTest
```

**Elixir** (if Mix configured)
```bash
cd packages/elixir && mix test test/serialization_test.exs
```

### By Feature

**Minimal Config**
```bash
pytest tests/cross_language_serialization_test.py::test_rust_vs_python_serialization[minimal] -v
```

**Full Config**
```bash
pytest tests/cross_language_serialization_test.py::test_rust_vs_python_serialization[full] -v
```

**Round-Trip Tests**
```bash
pytest tests/cross_language_serialization_test.py -k "round_trip" -v
```

**Field Parity**
```bash
pytest tests/cross_language_serialization_test.py::test_field_name_mapping -v
```

## Expected Results

### Successful Test Run

```
tests/cross_language_serialization_test.py::test_field_name_mapping PASSED
tests/cross_language_serialization_test.py::test_python_extraction_config_serialization PASSED
tests/cross_language_serialization_test.py::test_serialization_round_trip PASSED
tests/cross_language_serialization_test.py::test_rust_vs_python_serialization[minimal] PASSED
tests/cross_language_serialization_test.py::test_rust_vs_python_serialization[full] PASSED
...

9 passed in 2.34s
```

### Field Mapping Example

```
use_cache:
  rust: use_cache
  python: use_cache
  typescript: useCache
  ruby: use_cache
  go: UseCache
  java: useCache
  php: use_cache
  csharp: UseCache
  elixir: use_cache
```

## Validation Checklist

When running tests, verify:

- [ ] All Rust integration tests pass
- [ ] Python serialization tests pass
- [ ] TypeScript camelCase naming used
- [ ] Ruby snake_case naming preserved
- [ ] Go PascalCase naming used
- [ ] Java camelCase naming used
- [ ] PHP snake_case naming preserved
- [ ] C# PascalCase naming used
- [ ] Elixir snake_case naming preserved
- [ ] Round-trip tests preserve all fields
- [ ] Null/empty values handled correctly
- [ ] Nested structures serialize properly
- [ ] All mandatory fields present

## Troubleshooting

### Helper Binary Not Found
```bash
cargo build --bin extraction_config_json_helper --release
```

### Python Binding Not Installed
```bash
cd packages/python && pip install -e .
```

### Tests Skipped
Some tests are skipped if the corresponding language binding is not available. This is expected and not a failure.

To run only available tests:
```bash
pytest tests/cross_language_serialization_test.py -v --tb=short
```

### JSON Parse Errors
If you see JSON parsing errors, ensure:
1. The Rust helper binary is built: `cargo build --bin extraction_config_json_helper`
2. The config dictionary is valid JSON-serializable
3. Required fields are present in output

## Integration with CI/CD

### GitHub Actions Example

```yaml
- name: Run Serialization Tests
  run: |
    pytest tests/cross_language_serialization_test.py -v
    cargo test --test serialization_integration

- name: Run Language-Specific Tests
  run: |
    cd packages/typescript && npm test -- serialization.spec.ts
    cd ../ruby && bundle exec rspec spec/serialization_spec.rb
```

### Pre-Commit Hook

```bash
#!/bin/bash
pytest tests/cross_language_serialization_test.py -q
cargo test --test serialization_integration --quiet
```

## Performance

- **Python tests**: ~2-3 seconds
- **Rust tests**: ~1-2 seconds
- **TypeScript tests**: ~5-10 seconds (includes npm overhead)
- **Ruby tests**: ~3-5 seconds
- **Go tests**: ~2-3 seconds
- **Total**: ~15-25 seconds

## Documentation

For detailed information, see:
- `SERIALIZATION_TESTS.md` - Complete test documentation
- Individual language test files - Language-specific details
- `src/bin/extraction_config_json_helper.rs` - Helper binary source

## Next Steps

To extend the test suite:

1. **Add new fixtures** in `EXTRACTION_CONFIG_FIXTURES`
2. **Update field mappings** in `test_field_name_mapping()`
3. **Add language-specific tests** in respective directories
4. **Update documentation** with new test details
5. **Run full test suite** to validate changes

## Support

For issues or questions:
1. Check `SERIALIZATION_TESTS.md` for detailed documentation
2. Review language-specific test files for implementation details
3. Examine helper binary source for serialization logic
4. Consult API parity rule: `.ai-rulez/rules/api-reference-parity-across-bindings.md`

## License

These tests are part of the Kreuzberg project and follow the same license terms.
