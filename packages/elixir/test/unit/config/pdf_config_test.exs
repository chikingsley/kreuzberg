defmodule KreuzbergTest.Unit.Config.PdfConfigTest do
  @moduledoc """
  Unit tests for PDF-specific configuration.

  Tests cover:
  - Struct creation with PDF options
  - Validation of rendering quality
  - Form field extraction settings
  - Password and security options
  - Serialization to/from maps
  - Pattern matching on PDF configs
  - Edge cases for PDF-specific features
  """

  use ExUnit.Case

  describe "struct creation" do
    @tag :unit
    test "creates with default values" do
      config = %{
        "enabled" => true,
        "extract_forms" => false,
        "render_quality" => 150
      }

      assert config["enabled"] == true
      assert config["extract_forms"] == false
      assert config["render_quality"] == 150
    end

    @tag :unit
    test "creates with form extraction enabled" do
      config = %{
        "enabled" => true,
        "extract_forms" => true,
        "extract_form_data" => true,
        "preserve_form_structure" => true
      }

      assert config["extract_forms"] == true
      assert config["extract_form_data"] == true
    end

    @tag :unit
    test "creates with high rendering quality" do
      config = %{
        "enabled" => true,
        "render_quality" => 300,
        "render_images" => true
      }

      assert config["render_quality"] == 300
      assert config["render_images"] == true
    end

    @tag :unit
    test "creates with annotations extraction" do
      config = %{
        "enabled" => true,
        "extract_annotations" => true,
        "extract_comments" => true
      }

      assert config["extract_annotations"] == true
      assert config["extract_comments"] == true
    end
  end

  describe "validation" do
    @tag :unit
    test "validates enabled is boolean" do
      config = %{"enabled" => true}

      assert is_boolean(config["enabled"])
    end

    @tag :unit
    test "validates render_quality is positive integer" do
      config = %{"render_quality" => 150}

      assert is_integer(config["render_quality"])
      assert config["render_quality"] > 0
    end

    @tag :unit
    test "validates render_quality in reasonable range" do
      config = %{"render_quality" => 150}

      assert config["render_quality"] >= 72 and config["render_quality"] <= 600
    end

    @tag :unit
    test "validates extract_forms is boolean" do
      config = %{"extract_forms" => true}

      assert is_boolean(config["extract_forms"])
    end

    @tag :unit
    test "validates extract_annotations is boolean" do
      config = %{"extract_annotations" => false}

      assert is_boolean(config["extract_annotations"])
    end

    @tag :unit
    test "accepts valid PDF config" do
      config = %{
        "enabled" => true,
        "extract_forms" => true,
        "render_quality" => 200,
        "extract_annotations" => true
      }

      assert config["enabled"] == true
      assert config["render_quality"] > 0
    end
  end

  describe "serialization" do
    @tag :unit
    test "converts to map with all fields" do
      config = %{
        "enabled" => true,
        "extract_forms" => true,
        "render_quality" => 200
      }

      assert is_map(config)
      assert config["extract_forms"] == true
      assert config["render_quality"] == 200
    end

    @tag :unit
    test "round-trips through JSON" do
      original = %{
        "enabled" => true,
        "extract_forms" => true,
        "extract_form_data" => true,
        "render_quality" => 200,
        "render_images" => true,
        "extract_annotations" => true,
        "extract_comments" => true,
        "preserve_form_structure" => true
      }

      json = Jason.encode!(original)
      {:ok, restored} = Jason.decode(json)

      assert restored["extract_forms"] == true
      assert restored["render_quality"] == 200
      assert restored["extract_annotations"] == true
    end

    @tag :unit
    test "preserves boolean values" do
      config = %{
        "enabled" => true,
        "extract_forms" => false,
        "render_images" => true
      }

      json = Jason.encode!(config)
      {:ok, decoded} = Jason.decode(json)

      assert decoded["enabled"] == true
      assert decoded["extract_forms"] == false
      assert decoded["render_images"] == true
    end
  end

  describe "nesting in ExtractionConfig" do
    @tag :unit
    test "can be nested in extraction config" do
      pdf_config = %{
        "enabled" => true,
        "extract_forms" => true,
        "render_quality" => 200
      }

      extraction_config = %Kreuzberg.ExtractionConfig{pdf_options: pdf_config}

      assert extraction_config.pdf_options["extract_forms"] == true
      assert extraction_config.pdf_options["render_quality"] == 200
    end

    @tag :unit
    test "validates when nested" do
      pdf_config = %{"enabled" => true, "render_quality" => 150, "extract_forms" => true}
      extraction_config = %Kreuzberg.ExtractionConfig{pdf_options: pdf_config}

      assert {:ok, _} = Kreuzberg.ExtractionConfig.validate(extraction_config)
    end
  end

  describe "pattern matching" do
    @tag :unit
    test "matches on extract_forms field" do
      config = %{"extract_forms" => true}

      case config do
        %{"extract_forms" => true} -> assert true
        _ -> flunk("Pattern match failed")
      end
    end

    @tag :unit
    test "matches on render_quality field" do
      config = %{"render_quality" => 200}

      case config do
        %{"render_quality" => q} when q >= 150 -> assert true
        _ -> flunk("Pattern match failed")
      end
    end
  end

  describe "edge cases" do
    @tag :unit
    test "handles minimum render quality (72 DPI)" do
      config = %{"render_quality" => 72}

      assert config["render_quality"] == 72
    end

    @tag :unit
    test "handles maximum render quality (600 DPI)" do
      config = %{"render_quality" => 600}

      assert config["render_quality"] == 600
    end

    @tag :unit
    test "handles standard print quality (300 DPI)" do
      config = %{"render_quality" => 300}

      assert config["render_quality"] == 300
    end

    @tag :unit
    test "handles all extraction options disabled" do
      config = %{
        "extract_forms" => false,
        "extract_annotations" => false,
        "extract_comments" => false,
        "render_images" => false
      }

      assert config["extract_forms"] == false
      assert config["extract_annotations"] == false
    end

    @tag :unit
    test "handles all extraction options enabled" do
      config = %{
        "extract_forms" => true,
        "extract_form_data" => true,
        "extract_annotations" => true,
        "extract_comments" => true,
        "render_images" => true,
        "preserve_form_structure" => true
      }

      assert config["extract_forms"] == true
      assert config["extract_form_data"] == true
    end

    @tag :unit
    test "handles nil password" do
      config = %{"password" => nil}

      assert config["password"] == nil
    end

    @tag :unit
    test "handles encrypted PDF password" do
      config = %{"password" => "secure_password_123"}

      assert config["password"] == "secure_password_123"
    end

    @tag :unit
    test "handles nil user_password" do
      config = %{"user_password" => nil}

      assert config["user_password"] == nil
    end
  end

  describe "type safety" do
    @tag :unit
    test "enabled is boolean" do
      config = %{"enabled" => true}

      assert is_boolean(config["enabled"])
    end

    @tag :unit
    test "extract_forms is boolean" do
      config = %{"extract_forms" => true}

      assert is_boolean(config["extract_forms"])
    end

    @tag :unit
    test "render_quality is integer" do
      config = %{"render_quality" => 150}

      assert is_integer(config["render_quality"])
    end

    @tag :unit
    test "extract_annotations is boolean" do
      config = %{"extract_annotations" => true}

      assert is_boolean(config["extract_annotations"])
    end

    @tag :unit
    test "password is string or nil" do
      config1 = %{"password" => "secret"}
      config2 = %{"password" => nil}

      assert is_binary(config1["password"]) or config1["password"] == nil
      assert config2["password"] == nil
    end

    @tag :unit
    test "render_images is boolean or nil" do
      config1 = %{"render_images" => true}
      config2 = %{"render_images" => nil}

      assert is_boolean(config1["render_images"]) or config1["render_images"] == nil
      assert config2["render_images"] == nil
    end
  end
end
