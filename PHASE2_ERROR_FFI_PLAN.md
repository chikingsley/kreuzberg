# Phase 2 FFI Error Classification - Ruby Bindings Implementation Plan

## Current Status

The Phase 2 error FFI functions have NOT yet been implemented in the Rust FFI crate. This task requires waiting for the rust-core-engineer to complete the implementation first.

## Background: FFI Architecture

### Phase 1 (Already Implemented)
Config-related FFI functions in `crates/kreuzberg-ffi/src/lib.rs`:
- `kreuzberg_config_from_json()` - Parse config from JSON
- `kreuzberg_config_to_json()` - Serialize config to JSON
- `kreuzberg_config_get_field()` - Get specific field from config
- `kreuzberg_config_merge()` - Merge two config objects
- `kreuzberg_config_is_valid()` - Validate config JSON

Ruby Magnus wrappers in `packages/ruby/ext/kreuzberg_rb/native/src/lib.rs`:
- `config_to_json_wrapper()` - Wraps `kreuzberg_config_to_json()`
- `config_get_field_wrapper()` - Wraps `kreuzberg_config_get_field()`
- `config_merge_wrapper()` - Wraps `kreuzberg_config_merge()`

### Phase 2 (To Be Implemented)
Error classification FFI functions needed in `crates/kreuzberg-ffi/src/lib.rs`:
- `kreuzberg_get_error_details()` - Return structured error info (message, code, panic context)
- `kreuzberg_classify_error(error_message: String)` - Classify error by analyzing message
- `kreuzberg_error_code_name(code: u32)` - Get human-readable name for error code (may already exist)

Currently exists:
- `kreuzberg_last_error_code()` - Already implemented
- `kreuzberg_last_panic_context()` - Already implemented
- `kreuzberg_error_code_name()` - Already in error.rs but may need to be exposed in lib.rs

## Ruby Current Error Handling

### Current Error Classes (packages/ruby/lib/kreuzberg/errors.rb)
```ruby
module Kreuzberg::Errors
  class Error < StandardError
    attr_reader :panic_context, :error_code
  end

  class ValidationError < Error; end
  class ParsingError < Error; end
  class OCRError < Error; end
  class MissingDependencyError < Error; end
  class IOError < Error; end
  class PluginError < Error; end
  class UnsupportedFormatError < Error; end
end
```

### Current Error Codes (packages/ruby/lib/kreuzberg/errors.rb)
```ruby
ERROR_CODE_SUCCESS = 0
ERROR_CODE_GENERIC = 1
ERROR_CODE_PANIC = 2
ERROR_CODE_INVALID_ARGUMENT = 3
ERROR_CODE_IO = 4
ERROR_CODE_PARSING = 5
ERROR_CODE_OCR = 6
ERROR_CODE_MISSING_DEPENDENCY = 7
```

## Implementation Steps (Waiting for Phase 2)

### Step 1: Rust Core Engineer (BLOCKED - WAITING)
Implement Phase 2 FFI functions in `crates/kreuzberg-ffi/src/lib.rs`:

```rust
// Get structured error details (message, code, panic context)
#[no_mangle]
pub extern "C" fn kreuzberg_get_error_details() -> *mut c_char {
    // Returns JSON: {"message": "...", "code": 0, "panic_context": null}
    // Encodes the last error message, code, and panic context as a JSON object
}

// Classify error based on message analysis
#[no_mangle]
pub extern "C" fn kreuzberg_classify_error(error_message: *const c_char) -> i32 {
    // Returns error code (0-7) based on message pattern matching
    // Maps error messages to appropriate error codes
}

// Get error code name (ensure it's exported in lib.rs if in error.rs)
#[no_mangle]
pub extern "C" fn kreuzberg_error_code_name(code: u32) -> *const c_char {
    // Returns "Validation", "Parsing", "OCR", etc.
    // Should map error codes to human-readable names
}
```

### Step 2: Ruby Magnus FFI Wrappers
Add declarations in `packages/ruby/ext/kreuzberg_rb/native/src/lib.rs`:

```rust
#[link(name = "kreuzberg_ffi", kind = "static")]
unsafe extern "C" {
    pub fn kreuzberg_get_error_details() -> *mut c_char;
    pub fn kreuzberg_classify_error(error_message: *const c_char) -> i32;
    pub fn kreuzberg_error_code_name(code: u32) -> *const c_char;
}

// Wrapper functions
fn get_error_details(_ruby: &Ruby) -> Result<String, Error> {
    unsafe {
        let ptr = kreuzberg_get_error_details();
        if ptr.is_null() {
            return Err(runtime_error("Failed to get error details"));
        }

        let c_str = std::ffi::CStr::from_ptr(ptr);
        let details = c_str
            .to_string_lossy()
            .to_string();
        kreuzberg_free_string(ptr as *mut c_char);
        Ok(details)
    }
}

fn classify_error(_ruby: &Ruby, error_message: String) -> Result<i32, Error> {
    let c_msg = std::ffi::CString::new(error_message)
        .map_err(|e| runtime_error(format!("Invalid error message: {}", e)))?;

    unsafe {
        let code = kreuzberg_classify_error(c_msg.as_ptr());
        Ok(code)
    }
}

fn error_code_name(_ruby: &Ruby, code: u32) -> Result<String, Error> {
    unsafe {
        let ptr = kreuzberg_error_code_name(code);
        if ptr.is_null() {
            return Ok("Unknown".to_string());
        }

        let c_str = std::ffi::CStr::from_ptr(ptr);
        Ok(c_str.to_string_lossy().to_string())
    }
}
```

### Step 3: Update Ruby Module Functions
Register in Magnus initialization in `packages/ruby/ext/kreuzberg_rb/native/src/lib.rs`:

```rust
module.define_module_function("_get_error_details_native", function!(get_error_details, 0))?;
module.define_module_function("_classify_error_native", function!(classify_error, 1))?;
module.define_module_function("_error_code_name_native", function!(error_code_name, 1))?;
```

### Step 4: Update Ruby Error Handling (packages/ruby/lib/kreuzberg/errors.rb)
Add ErrorDetailsProvider module to use FFI error classification:

```ruby
module Kreuzberg
  module Errors
    # Provides access to FFI error classification functions
    module ErrorDetailsProvider
      class << self
        def get_details
          json_str = Kreuzberg._get_error_details_native
          return nil unless json_str
          JSON.parse(json_str, symbolize_names: true)
        rescue JSON::ParserError
          nil
        end

        def classify_message(message)
          Kreuzberg._classify_error_native(message)
        rescue StandardError
          ERROR_CODE_GENERIC
        end

        def code_name(code)
          Kreuzberg._error_code_name_native(code)
        rescue StandardError
          "Unknown"
        end
      end
    end
  end
end
```

### Step 5: Remove Duplicate Error Classification Logic
- Remove any string pattern matching for error classification in Ruby
- Update error context retrieval to use FFI functions where applicable
- Keep exception class definitions unchanged (Phase 1 requirement)

### Step 6: Testing
Run test suite to verify all error handling still works:
```bash
cd packages/ruby
bundle install
bundle exec rake compile
bundle exec rspec
```

## Benefits of Phase 2

1. **Single Source of Truth**: Error classification logic lives only in Rust core
2. **Cross-Language Consistency**: All bindings use identical error classification
3. **Maintainability**: Changes to error handling only need Rust core updates
4. **Performance**: FFI calls are more efficient than Ruby string parsing
5. **Type Safety**: Structured error details prevent inconsistencies
6. **Future-Proof**: Easy to extend with new error codes without Ruby changes

## File Changes Summary

### Rust FFI (crates/kreuzberg-ffi/src/lib.rs)
- Add three new #[no_mangle] functions for error classification
- Ensure error_code_name is properly exported from error.rs

### Ruby Magnus (packages/ruby/ext/kreuzberg_rb/native/src/lib.rs)
- Add FFI function declarations in unsafe extern "C" block
- Implement three wrapper functions with proper C string handling
- Export functions as Ruby module methods

### Ruby Gem (packages/ruby/lib/kreuzberg/errors.rb)
- Add ErrorDetailsProvider module for FFI access
- Update error context to use FFI functions
- Remove any duplicate error classification logic
- Keep existing error classes unchanged

### Ruby Gem (packages/ruby/lib/kreuzberg/error_context.rb)
- May need minor updates if using new FFI functions
- Should remain mostly unchanged

## Blocked Waiting For

The rust-core-engineer must implement the three Phase 2 FFI functions in the kreuzberg-ffi crate before Ruby binding work can proceed.

## Key Implementation Notes

1. **Pattern**: Follow the config FFI wrapper patterns already in place (Phase 1)
2. **Memory Management**: Always free C strings returned from FFI with `kreuzberg_free_string()`
3. **Error Handling**: Use `runtime_error()` for FFI wrapper errors
4. **Thread Safety**: FFI error context is thread-local; each thread maintains its own state
5. **Testing**: Existing test suite should pass without changes after implementation
6. **Backwards Compatibility**: Exception classes remain unchanged; only internals updated

## Timeline Estimate

- Phase 2 FFI functions: rust-core-engineer (blocked, waiting)
- Ruby Magnus wrappers: 1-2 hours (straightforward, follows Phase 1 pattern)
- Ruby error module updates: 1-2 hours (minimal changes needed)
- Testing and verification: 30-45 minutes
- **Total**: Depends on Phase 2 completion, then ~3-4 hours for Ruby work
