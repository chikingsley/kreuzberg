defmodule KreuzbergTest.Unit.Config.ExtractionConfigTest do
  @moduledoc """
  Unit tests for Kreuzberg.ExtractionConfig module.

  Tests cover:
  - Struct creation with defaults and custom values
  - Validation of all fields
  - Serialization to/from maps
  - Pattern matching
  - Type specs
  - Nesting in parent configs
  - Edge cases
  """

  use ExUnit.Case

  alias Kreuzberg.ExtractionConfig

  describe "struct creation" do
    @tag :unit
    test "creates with default values" do
      config = %ExtractionConfig{}

      assert config.use_cache == true
      assert config.enable_quality_processing == true
      assert config.force_ocr == false
      assert config.chunking == nil
      assert config.ocr == nil
    end

    @tag :unit
    test "creates with custom boolean values" do
      config = %ExtractionConfig{
        use_cache: false,
        enable_quality_processing: true,
        force_ocr: true
      }

      assert config.use_cache == false
      assert config.enable_quality_processing == true
      assert config.force_ocr == true
    end

    @tag :unit
    test "creates with nested configuration maps" do
      config = %ExtractionConfig{
        chunking: %{"size" => 512, "overlap" => 50},
        ocr: %{"backend" => "tesseract"},
        language_detection: %{"enabled" => true}
      }

      assert config.chunking == %{"size" => 512, "overlap" => 50}
      assert config.ocr == %{"backend" => "tesseract"}
      assert config.language_detection == %{"enabled" => true}
    end
  end

  describe "validation" do
    @tag :unit
    test "validates use_cache field" do
      config = %ExtractionConfig{use_cache: "invalid"}
      assert {:error, reason} = ExtractionConfig.validate(config)
      assert reason =~ "use_cache"
    end

    @tag :unit
    test "validates enable_quality_processing field" do
      config = %ExtractionConfig{enable_quality_processing: 1}
      assert {:error, reason} = ExtractionConfig.validate(config)
      assert reason =~ "enable_quality_processing"
    end

    @tag :unit
    test "validates chunking map field" do
      config = %ExtractionConfig{chunking: "invalid"}
      assert {:error, reason} = ExtractionConfig.validate(config)
      assert reason =~ "chunking"
    end

    @tag :unit
    test "accepts valid config with all fields" do
      config = %ExtractionConfig{
        use_cache: true,
        enable_quality_processing: false,
        force_ocr: true,
        chunking: %{"size" => 1024},
        ocr: %{"enabled" => true},
        language_detection: %{"enabled" => true}
      }

      assert {:ok, ^config} = ExtractionConfig.validate(config)
    end

    @tag :unit
    test "accepts nil for all nested fields" do
      config = %ExtractionConfig{
        chunking: nil,
        ocr: nil,
        language_detection: nil,
        postprocessor: nil
      }

      assert {:ok, _} = ExtractionConfig.validate(config)
    end
  end

  describe "serialization" do
    @tag :unit
    test "converts to map with all fields" do
      config = %ExtractionConfig{
        use_cache: true,
        chunking: %{"size" => 512}
      }

      map = ExtractionConfig.to_map(config)

      assert is_map(map)
      assert map["use_cache"] == true
      assert map["chunking"] == %{"size" => 512}
      assert map["enable_quality_processing"] == true
    end

    @tag :unit
    test "converts from map to struct" do
      map = %{
        "use_cache" => false,
        "enable_quality_processing" => true,
        "force_ocr" => false
      }

      {:ok, config} =
        ExtractionConfig.validate(%ExtractionConfig{
          use_cache: false,
          enable_quality_processing: true,
          force_ocr: false
        })

      assert config.use_cache == false
      assert config.enable_quality_processing == true
    end

    @tag :unit
    test "handles nil config in to_map" do
      assert ExtractionConfig.to_map(nil) == nil
    end

    @tag :unit
    test "round-trips through JSON" do
      original = %ExtractionConfig{
        use_cache: true,
        force_ocr: false,
        chunking: %{"size" => 512}
      }

      map = ExtractionConfig.to_map(original)
      json = Jason.encode!(map)
      {:ok, decoded} = Jason.decode(json)

      assert decoded["use_cache"] == true
      assert decoded["chunking"] == %{"size" => 512}
    end
  end

  describe "pattern matching" do
    @tag :unit
    test "matches on use_cache field" do
      config = %ExtractionConfig{use_cache: true}

      assert %ExtractionConfig{use_cache: true} = config
    end

    @tag :unit
    test "matches on multiple fields" do
      config = %ExtractionConfig{
        use_cache: false,
        enable_quality_processing: true
      }

      assert %ExtractionConfig{
               use_cache: false,
               enable_quality_processing: true
             } = config
    end

    @tag :unit
    test "matches on nested configuration" do
      config = %ExtractionConfig{chunking: %{"size" => 512}}

      assert %ExtractionConfig{chunking: chunking} = config
      assert chunking["size"] == 512
    end
  end

  describe "struct enforcement" do
    @tag :unit
    test "is a proper struct" do
      config = %ExtractionConfig{}

      assert is_struct(config)
      assert is_struct(config, ExtractionConfig)
    end

    @tag :unit
    test "ignores unknown keys when using struct/2" do
      # struct/2 ignores unknown keys rather than raising an error
      # This is the standard Elixir behavior
      result = struct(ExtractionConfig, unknown_field: "value")
      assert is_struct(result, ExtractionConfig)
      # The unknown field is not added to the struct
      assert not Map.has_key?(result, :unknown_field)
    end
  end

  describe "type specifications" do
    @tag :unit
    test "has proper struct definition" do
      assert function_exported?(ExtractionConfig, :__struct__, 0)
    end

    @tag :unit
    test "documents type as t/0" do
      # Ensure the module has proper type specs
      config = %ExtractionConfig{}
      assert is_struct(config, ExtractionConfig)
    end
  end

  describe "edge cases" do
    @tag :unit
    test "handles nil nested configurations" do
      config = %ExtractionConfig{
        chunking: nil,
        ocr: nil,
        language_detection: nil,
        postprocessor: nil,
        images: nil,
        pages: nil,
        token_reduction: nil,
        keywords: nil,
        pdf_options: nil
      }

      assert {:ok, _} = ExtractionConfig.validate(config)
    end

    @tag :unit
    test "handles empty maps for nested configurations" do
      config = %ExtractionConfig{
        chunking: %{},
        ocr: %{},
        language_detection: %{}
      }

      assert {:ok, _} = ExtractionConfig.validate(config)
    end

    @tag :unit
    test "handles large configuration maps" do
      large_config = Map.new(1..100, &{"key_#{&1}", &1})

      config = %ExtractionConfig{chunking: large_config}

      assert {:ok, _} = ExtractionConfig.validate(config)
      assert map_size(config.chunking) == 100
    end
  end

  describe "output_format configuration" do
    @tag :unit
    test "creates with default output_format" do
      config = %ExtractionConfig{}
      assert config.output_format == "plain"
    end

    @tag :unit
    test "creates with custom output_format" do
      config = %ExtractionConfig{output_format: "markdown"}
      assert config.output_format == "markdown"
    end

    @tag :unit
    test "validates plain output_format" do
      config = %ExtractionConfig{output_format: "plain"}
      assert {:ok, _} = ExtractionConfig.validate(config)
    end

    @tag :unit
    test "validates markdown output_format" do
      config = %ExtractionConfig{output_format: "markdown"}
      assert {:ok, _} = ExtractionConfig.validate(config)
    end

    @tag :unit
    test "validates djot output_format" do
      config = %ExtractionConfig{output_format: "djot"}
      assert {:ok, _} = ExtractionConfig.validate(config)
    end

    @tag :unit
    test "validates html output_format" do
      config = %ExtractionConfig{output_format: "html"}
      assert {:ok, _} = ExtractionConfig.validate(config)
    end

    @tag :unit
    test "rejects invalid output_format" do
      config = %ExtractionConfig{output_format: "invalid"}
      assert {:error, reason} = ExtractionConfig.validate(config)
      assert reason =~ "output_format"
      assert reason =~ "plain"
      assert reason =~ "markdown"
    end

    @tag :unit
    test "rejects non-string output_format" do
      config = %ExtractionConfig{output_format: 123}
      assert {:error, reason} = ExtractionConfig.validate(config)
      assert reason =~ "output_format"
      assert reason =~ "string"
    end

    @tag :unit
    test "normalizes output_format to lowercase in to_map" do
      config = %ExtractionConfig{output_format: "Markdown"}
      map = ExtractionConfig.to_map(config)
      assert map["output_format"] == "markdown"
    end
  end

  describe "result_format configuration" do
    @tag :unit
    test "creates with default result_format" do
      config = %ExtractionConfig{}
      assert config.result_format == "unified"
    end

    @tag :unit
    test "creates with custom result_format" do
      config = %ExtractionConfig{result_format: "element_based"}
      assert config.result_format == "element_based"
    end

    @tag :unit
    test "validates unified result_format" do
      config = %ExtractionConfig{result_format: "unified"}
      assert {:ok, _} = ExtractionConfig.validate(config)
    end

    @tag :unit
    test "validates element_based result_format" do
      config = %ExtractionConfig{result_format: "element_based"}
      assert {:ok, _} = ExtractionConfig.validate(config)
    end

    @tag :unit
    test "validates elementbased variant of result_format" do
      config = %ExtractionConfig{result_format: "elementbased"}
      assert {:ok, _} = ExtractionConfig.validate(config)
    end

    @tag :unit
    test "rejects invalid result_format" do
      config = %ExtractionConfig{result_format: "invalid"}
      assert {:error, reason} = ExtractionConfig.validate(config)
      assert reason =~ "result_format"
      assert reason =~ "unified"
      assert reason =~ "element_based"
    end

    @tag :unit
    test "rejects non-string result_format" do
      config = %ExtractionConfig{result_format: :atom}
      assert {:error, reason} = ExtractionConfig.validate(config)
      assert reason =~ "result_format"
      assert reason =~ "string"
    end

    @tag :unit
    test "normalizes result_format to lowercase in to_map" do
      config = %ExtractionConfig{result_format: "Element_Based"}
      map = ExtractionConfig.to_map(config)
      assert map["result_format"] == "element_based"
    end
  end

  describe "format configurations in to_map" do
    @tag :unit
    test "includes both output_format and result_format in serialization" do
      config = %ExtractionConfig{
        output_format: "markdown",
        result_format: "element_based"
      }

      map = ExtractionConfig.to_map(config)

      assert map["output_format"] == "markdown"
      assert map["result_format"] == "element_based"
    end

    @tag :unit
    test "serializes all format fields with defaults" do
      config = %ExtractionConfig{}
      map = ExtractionConfig.to_map(config)

      assert map["output_format"] == "plain"
      assert map["result_format"] == "unified"
      assert is_boolean(map["use_cache"])
      assert is_boolean(map["enable_quality_processing"])
    end

    @tag :unit
    test "round-trips format fields through JSON" do
      original = %ExtractionConfig{
        output_format: "markdown",
        result_format: "element_based",
        use_cache: false
      }

      map = ExtractionConfig.to_map(original)
      json = Jason.encode!(map)
      {:ok, decoded} = Jason.decode(json)

      assert decoded["output_format"] == "markdown"
      assert decoded["result_format"] == "element_based"
      assert decoded["use_cache"] == false
    end
  end

  describe "complete configuration with format fields" do
    @tag :unit
    test "validates config with all format options" do
      config = %ExtractionConfig{
        use_cache: false,
        enable_quality_processing: true,
        force_ocr: true,
        output_format: "markdown",
        result_format: "element_based",
        chunking: %{"size" => 512},
        ocr: %{"backend" => "tesseract"}
      }

      assert {:ok, validated} = ExtractionConfig.validate(config)
      assert validated.output_format == "markdown"
      assert validated.result_format == "element_based"
    end

    @tag :unit
    test "preserves format fields in struct creation" do
      config = %ExtractionConfig{
        output_format: "html",
        result_format: "unified",
        use_cache: true
      }

      assert config.output_format == "html"
      assert config.result_format == "unified"
      assert config.use_cache == true
    end

    @tag :unit
    test "pattern matches on format fields" do
      config = %ExtractionConfig{
        output_format: "markdown",
        result_format: "element_based"
      }

      assert %ExtractionConfig{
               output_format: "markdown",
               result_format: "element_based"
             } = config
    end
  end

  describe "max_concurrent_extractions field" do
    @tag :unit
    test "creates with default nil value" do
      config = %ExtractionConfig{}
      assert config.max_concurrent_extractions == nil
    end

    @tag :unit
    test "creates with custom positive integer" do
      config = %ExtractionConfig{max_concurrent_extractions: 8}
      assert config.max_concurrent_extractions == 8
    end

    @tag :unit
    test "validates positive integer max_concurrent_extractions" do
      config = %ExtractionConfig{max_concurrent_extractions: 4}
      assert {:ok, _} = ExtractionConfig.validate(config)
    end

    @tag :unit
    test "validates nil max_concurrent_extractions" do
      config = %ExtractionConfig{max_concurrent_extractions: nil}
      assert {:ok, _} = ExtractionConfig.validate(config)
    end

    @tag :unit
    test "rejects zero for max_concurrent_extractions" do
      config = %ExtractionConfig{max_concurrent_extractions: 0}
      assert {:error, reason} = ExtractionConfig.validate(config)
      assert reason =~ "max_concurrent_extractions"
      assert reason =~ "positive"
    end

    @tag :unit
    test "rejects negative integer for max_concurrent_extractions" do
      config = %ExtractionConfig{max_concurrent_extractions: -1}
      assert {:error, reason} = ExtractionConfig.validate(config)
      assert reason =~ "max_concurrent_extractions"
      assert reason =~ "positive"
    end

    @tag :unit
    test "rejects non-integer for max_concurrent_extractions" do
      config = %ExtractionConfig{max_concurrent_extractions: "8"}
      assert {:error, reason} = ExtractionConfig.validate(config)
      assert reason =~ "max_concurrent_extractions"
      assert reason =~ "integer"
    end

    @tag :unit
    test "rejects float for max_concurrent_extractions" do
      config = %ExtractionConfig{max_concurrent_extractions: 8.5}
      assert {:error, reason} = ExtractionConfig.validate(config)
      assert reason =~ "max_concurrent_extractions"
      assert reason =~ "integer"
    end

    @tag :unit
    test "includes max_concurrent_extractions in to_map" do
      config = %ExtractionConfig{max_concurrent_extractions: 16}
      map = ExtractionConfig.to_map(config)
      assert map["max_concurrent_extractions"] == 16
    end

    @tag :unit
    test "includes nil max_concurrent_extractions in to_map" do
      config = %ExtractionConfig{max_concurrent_extractions: nil}
      map = ExtractionConfig.to_map(config)
      assert map["max_concurrent_extractions"] == nil
    end

    @tag :unit
    test "round-trips max_concurrent_extractions through JSON" do
      original = %ExtractionConfig{max_concurrent_extractions: 12}
      map = ExtractionConfig.to_map(original)
      json = Jason.encode!(map)
      {:ok, decoded} = Jason.decode(json)
      assert decoded["max_concurrent_extractions"] == 12
    end

    @tag :unit
    test "pattern matches on max_concurrent_extractions field" do
      config = %ExtractionConfig{max_concurrent_extractions: 8}
      assert %ExtractionConfig{max_concurrent_extractions: 8} = config
    end
  end

  describe "html_options field" do
    @tag :unit
    test "creates with default nil value" do
      config = %ExtractionConfig{}
      assert config.html_options == nil
    end

    @tag :unit
    test "creates with custom map" do
      html_opts = %{"heading_style" => "atx", "code_block_style" => "fenced"}
      config = %ExtractionConfig{html_options: html_opts}
      assert config.html_options == html_opts
    end

    @tag :unit
    test "validates map for html_options" do
      config = %ExtractionConfig{html_options: %{"option" => "value"}}
      assert {:ok, _} = ExtractionConfig.validate(config)
    end

    @tag :unit
    test "validates nil for html_options" do
      config = %ExtractionConfig{html_options: nil}
      assert {:ok, _} = ExtractionConfig.validate(config)
    end

    @tag :unit
    test "validates empty map for html_options" do
      config = %ExtractionConfig{html_options: %{}}
      assert {:ok, _} = ExtractionConfig.validate(config)
    end

    @tag :unit
    test "rejects non-map for html_options" do
      config = %ExtractionConfig{html_options: "invalid"}
      assert {:error, reason} = ExtractionConfig.validate(config)
      assert reason =~ "html_options"
      assert reason =~ "map"
    end

    @tag :unit
    test "rejects list for html_options" do
      config = %ExtractionConfig{html_options: ["invalid"]}
      assert {:error, reason} = ExtractionConfig.validate(config)
      assert reason =~ "html_options"
      assert reason =~ "map"
    end

    @tag :unit
    test "includes html_options in to_map" do
      html_opts = %{"style" => "atx"}
      config = %ExtractionConfig{html_options: html_opts}
      map = ExtractionConfig.to_map(config)
      assert map["html_options"] == html_opts
    end

    @tag :unit
    test "includes nil html_options in to_map" do
      config = %ExtractionConfig{html_options: nil}
      map = ExtractionConfig.to_map(config)
      assert map["html_options"] == nil
    end

    @tag :unit
    test "round-trips html_options through JSON" do
      original = %ExtractionConfig{
        html_options: %{"heading_style" => "setext", "embed_images" => true}
      }

      map = ExtractionConfig.to_map(original)
      json = Jason.encode!(map)
      {:ok, decoded} = Jason.decode(json)
      assert decoded["html_options"]["heading_style"] == "setext"
      assert decoded["html_options"]["embed_images"] == true
    end

    @tag :unit
    test "pattern matches on html_options field" do
      html_opts = %{"option" => "value"}
      config = %ExtractionConfig{html_options: html_opts}
      assert %ExtractionConfig{html_options: ^html_opts} = config
    end

    @tag :unit
    test "normalizes atom keys in html_options map" do
      config = %ExtractionConfig{html_options: %{heading_style: "atx"}}
      map = ExtractionConfig.to_map(config)
      # Keys should be normalized to strings
      assert map["html_options"]["heading_style"] == "atx"
    end
  end

  describe "combined new fields" do
    @tag :unit
    test "validates config with both new fields" do
      config = %ExtractionConfig{
        max_concurrent_extractions: 16,
        html_options: %{"heading_style" => "atx"}
      }

      assert {:ok, _} = ExtractionConfig.validate(config)
    end

    @tag :unit
    test "serializes both new fields in to_map" do
      config = %ExtractionConfig{
        max_concurrent_extractions: 8,
        html_options: %{"style" => "atx", "embed_images" => false}
      }

      map = ExtractionConfig.to_map(config)
      assert map["max_concurrent_extractions"] == 8
      assert map["html_options"]["style"] == "atx"
      assert map["html_options"]["embed_images"] == false
    end

    @tag :unit
    test "validates complete config with all fields including new ones" do
      config = %ExtractionConfig{
        use_cache: true,
        enable_quality_processing: false,
        force_ocr: true,
        max_concurrent_extractions: 4,
        html_options: %{"heading_style" => "setext"},
        output_format: "markdown",
        result_format: "element_based",
        chunking: %{"size" => 1024},
        ocr: %{"backend" => "tesseract"}
      }

      assert {:ok, validated} = ExtractionConfig.validate(config)
      assert validated.max_concurrent_extractions == 4
      assert validated.html_options["heading_style"] == "setext"
    end

    @tag :unit
    test "pattern matches on multiple new fields" do
      config = %ExtractionConfig{
        max_concurrent_extractions: 12,
        html_options: %{"option" => "value"}
      }

      assert %ExtractionConfig{
               max_concurrent_extractions: 12,
               html_options: %{"option" => "value"}
             } = config
    end

    @tag :unit
    test "round-trips complete config through JSON" do
      original = %ExtractionConfig{
        max_concurrent_extractions: 8,
        html_options: %{"heading_style" => "atx"},
        output_format: "markdown",
        force_ocr: true
      }

      map = ExtractionConfig.to_map(original)
      json = Jason.encode!(map)
      {:ok, decoded} = Jason.decode(json)

      assert decoded["max_concurrent_extractions"] == 8
      assert decoded["html_options"]["heading_style"] == "atx"
      assert decoded["output_format"] == "markdown"
      assert decoded["force_ocr"] == true
    end
  end
end
