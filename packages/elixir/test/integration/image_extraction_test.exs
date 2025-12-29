defmodule KreuzbergTest.Integration.ImageExtractionTest do
  @moduledoc """
  Integration tests for image extraction functionality.

  Tests cover:
  - Image struct creation and manipulation
  - Image metadata (width, height, format, DPI)
  - Image data (binary/base64 handling)
  - OCR text extraction from images
  - Pattern matching on image structures
  - Image serialization and deserialization
  """

  use ExUnit.Case, async: true

  # Sample 1x1 PNG in base64 (valid PNG with minimal data)
  @sample_png_base64 "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="

  describe "Image struct creation" do
    @tag :integration
    test "creates Image struct with format" do
      image = Kreuzberg.Image.new("png")

      assert image.format == "png"
      assert %Kreuzberg.Image{} = image
    end

    @tag :integration
    test "creates Image struct with metadata" do
      image = Kreuzberg.Image.new("jpeg", width: 1920, height: 1080)

      assert image.format == "jpeg"
      assert image.width == 1920
      assert image.height == 1080
    end

    @tag :integration
    test "creates Image struct with DPI" do
      image = Kreuzberg.Image.new("png", dpi: 300)

      assert image.format == "png"
      assert image.dpi == 300
    end

    @tag :integration
    test "creates Image struct with OCR text" do
      image =
        Kreuzberg.Image.new(
          "png",
          width: 640,
          height: 480,
          ocr_text: "Extracted text from image"
        )

      assert image.ocr_text == "Extracted text from image"
      assert image.width == 640
      assert image.height == 480
    end

    @tag :integration
    test "creates Image struct with MIME type" do
      image =
        Kreuzberg.Image.new(
          "png",
          mime_type: "image/png"
        )

      assert image.format == "png"
      assert image.mime_type == "image/png"
    end

    @tag :integration
    test "creates Image struct with page number" do
      image =
        Kreuzberg.Image.new(
          "jpeg",
          page_number: 5
        )

      assert image.page_number == 5
    end

    @tag :integration
    test "creates Image struct from map" do
      image_map = %{
        "format" => "png",
        "width" => 800,
        "height" => 600,
        "dpi" => 150
      }

      image = Kreuzberg.Image.from_map(image_map)

      assert %Kreuzberg.Image{} = image
      assert image.format == "png"
      assert image.width == 800
      assert image.height == 600
      assert image.dpi == 150
    end
  end

  describe "Image data and metadata" do
    @tag :integration
    test "stores binary image data" do
      png_binary = Base.decode64!(@sample_png_base64)

      image =
        Kreuzberg.Image.new(
          "png",
          data: png_binary
        )

      assert image.data == png_binary
      assert is_binary(image.data)
      assert byte_size(image.data) > 0
    end

    @tag :integration
    test "calculates aspect ratio" do
      image = %Kreuzberg.Image{
        format: "png",
        width: 1920,
        height: 1080
      }

      aspect = Kreuzberg.Image.aspect_ratio(image)

      assert is_float(aspect) or is_integer(aspect)
      # 16:9 aspect ratio
      assert aspect > 1.0
    end

    @tag :integration
    test "aspect ratio for square image" do
      image = %Kreuzberg.Image{
        format: "jpeg",
        width: 512,
        height: 512
      }

      aspect = Kreuzberg.Image.aspect_ratio(image)

      assert aspect == 1.0
    end

    @tag :integration
    test "aspect ratio returns nil for missing dimensions" do
      image = %Kreuzberg.Image{
        format: "png"
      }

      aspect = Kreuzberg.Image.aspect_ratio(image)

      assert aspect == nil
    end

    @tag :integration
    test "checks if image has data" do
      image_with_data =
        Kreuzberg.Image.new(
          "png",
          data: Base.decode64!(@sample_png_base64)
        )

      image_without_data = Kreuzberg.Image.new("png")

      assert Kreuzberg.Image.has_data?(image_with_data)
      refute Kreuzberg.Image.has_data?(image_without_data)
    end

    @tag :integration
    test "tracks file size" do
      png_binary = Base.decode64!(@sample_png_base64)

      image =
        Kreuzberg.Image.new(
          "png",
          data: png_binary,
          file_size: byte_size(png_binary)
        )

      assert image.file_size == byte_size(png_binary)
    end
  end

  describe "Image format handling" do
    @tag :integration
    test "supports PNG format" do
      image = Kreuzberg.Image.new("png", dpi: 96)

      assert image.format == "png"
    end

    @tag :integration
    test "supports JPEG format" do
      image = Kreuzberg.Image.new("jpeg", dpi: 72)

      assert image.format == "jpeg"
    end

    @tag :integration
    test "supports WebP format" do
      image = Kreuzberg.Image.new("webp", dpi: 150)

      assert image.format == "webp"
    end

    @tag :integration
    test "supports TIFF format" do
      image = Kreuzberg.Image.new("tiff", dpi: 300)

      assert image.format == "tiff"
    end

    @tag :integration
    test "MIME type corresponds to format" do
      formats_and_mimes = [
        {"png", "image/png"},
        {"jpeg", "image/jpeg"},
        {"webp", "image/webp"},
        {"gif", "image/gif"}
      ]

      Enum.each(formats_and_mimes, fn {format, mime} ->
        image = Kreuzberg.Image.new(format, mime_type: mime)
        assert image.mime_type == mime
      end)
    end
  end

  describe "Image OCR results" do
    @tag :integration
    test "stores OCR extracted text" do
      ocr_text = """
      This is text extracted from an image.
      It can span multiple lines.
      And contain various formatting.
      """

      image =
        Kreuzberg.Image.new(
          "png",
          ocr_text: ocr_text
        )

      assert image.ocr_text == ocr_text
      assert String.length(image.ocr_text) > 0
    end

    @tag :integration
    test "handles empty OCR text" do
      image =
        Kreuzberg.Image.new(
          "png",
          ocr_text: ""
        )

      assert image.ocr_text == ""
    end

    @tag :integration
    test "OCR text with unicode characters" do
      unicode_text = "Chinese: 你好, Arabic: مرحبا, Emoji: 🖼️"

      image =
        Kreuzberg.Image.new(
          "jpeg",
          ocr_text: unicode_text
        )

      assert image.ocr_text == unicode_text
    end

    @tag :integration
    test "OCR text with special characters" do
      special_text = "Special chars: !@#$%^&*()_+-=[]{}|;:',.<>?/\\`~"

      image =
        Kreuzberg.Image.new(
          "png",
          ocr_text: special_text
        )

      assert image.ocr_text == special_text
    end
  end

  describe "Image serialization" do
    @tag :integration
    test "converts Image to map" do
      image =
        Kreuzberg.Image.new(
          "png",
          width: 640,
          height: 480,
          dpi: 150
        )

      image_map = Kreuzberg.Image.to_map(image)

      assert is_map(image_map)
      assert image_map["format"] == "png"
      assert image_map["width"] == 640
      assert image_map["height"] == 480
      assert image_map["dpi"] == 150
    end

    @tag :integration
    test "round-trips through serialization" do
      original =
        Kreuzberg.Image.new(
          "jpeg",
          width: 1024,
          height: 768,
          dpi: 200,
          mime_type: "image/jpeg",
          ocr_text: "Sample OCR text"
        )

      image_map = Kreuzberg.Image.to_map(original)
      restored = Kreuzberg.Image.from_map(image_map)

      assert restored.format == original.format
      assert restored.width == original.width
      assert restored.height == original.height
      assert restored.dpi == original.dpi
      assert restored.ocr_text == original.ocr_text
    end

    @tag :integration
    test "serializes to JSON" do
      image =
        Kreuzberg.Image.new(
          "png",
          width: 800,
          height: 600,
          dpi: 96,
          mime_type: "image/png",
          ocr_text: "Text in image"
        )

      image_map = Kreuzberg.Image.to_map(image)
      json = Jason.encode!(image_map)

      assert is_binary(json)
      {:ok, decoded} = Jason.decode(json)
      assert decoded["format"] == "png"
      assert decoded["width"] == 800
      assert decoded["ocr_text"] == "Text in image"
    end

    @tag :integration
    test "preserves metadata in serialization" do
      image =
        Kreuzberg.Image.new(
          "tiff",
          width: 2048,
          height: 1536,
          dpi: 300,
          page_number: 3
        )

      image_map = Kreuzberg.Image.to_map(image)
      json = Jason.encode!(image_map)
      {:ok, decoded} = Jason.decode(json)

      assert decoded["width"] == 2048
      assert decoded["height"] == 1536
      assert decoded["dpi"] == 300
      assert decoded["page_number"] == 3
    end
  end

  describe "Pattern matching on images" do
    @tag :integration
    test "matches on Image struct with format" do
      image = Kreuzberg.Image.new("png")

      case image do
        %Kreuzberg.Image{format: "png"} ->
          assert true

        _ ->
          flunk("Pattern match failed")
      end
    end

    @tag :integration
    test "matches on Image with dimensions" do
      image =
        Kreuzberg.Image.new(
          "jpeg",
          width: 1920,
          height: 1080
        )

      case image do
        %Kreuzberg.Image{width: w, height: h} when w > 1000 and h > 1000 ->
          assert true

        _ ->
          flunk("Dimension pattern match failed")
      end
    end

    @tag :integration
    test "matches on Image with OCR text" do
      image =
        Kreuzberg.Image.new(
          "png",
          ocr_text: "Some extracted text"
        )

      case image do
        %Kreuzberg.Image{ocr_text: text} when is_binary(text) ->
          assert true

        _ ->
          flunk("OCR text pattern match failed")
      end
    end

    @tag :integration
    test "matches on Image with high DPI" do
      image =
        Kreuzberg.Image.new(
          "png",
          dpi: 300
        )

      case image do
        %Kreuzberg.Image{dpi: dpi} when dpi >= 300 ->
          assert true

        _ ->
          flunk("DPI pattern match failed")
      end
    end
  end

  describe "Image dimensions and quality" do
    @tag :integration
    test "handles various width/height combinations" do
      test_dimensions = [
        # VGA
        {640, 480},
        # SVGA
        {800, 600},
        # XGA
        {1024, 768},
        # Full HD
        {1920, 1080},
        # QHD
        {2560, 1440}
      ]

      Enum.each(test_dimensions, fn {width, height} ->
        image = Kreuzberg.Image.new("jpeg", width: width, height: height)
        assert image.width == width
        assert image.height == height
      end)
    end

    @tag :integration
    test "handles various DPI values" do
      test_dpis = [72, 96, 150, 200, 300, 600]

      Enum.each(test_dpis, fn dpi ->
        image = Kreuzberg.Image.new("png", dpi: dpi)
        assert image.dpi == dpi
      end)
    end

    @tag :integration
    test "stores page number for multi-page documents" do
      image1 = Kreuzberg.Image.new("png", page_number: 1)
      image2 = Kreuzberg.Image.new("png", page_number: 2)
      image3 = Kreuzberg.Image.new("png", page_number: 3)

      assert image1.page_number == 1
      assert image2.page_number == 2
      assert image3.page_number == 3
    end
  end

  describe "Image edge cases" do
    @tag :integration
    test "handles very large dimensions" do
      image =
        Kreuzberg.Image.new(
          "tiff",
          width: 10_000,
          height: 10_000,
          dpi: 600
        )

      assert image.width == 10_000
      assert image.height == 10_000
    end

    @tag :integration
    test "handles minimal dimensions" do
      image =
        Kreuzberg.Image.new(
          "png",
          width: 1,
          height: 1
        )

      assert image.width == 1
      assert image.height == 1
      aspect = Kreuzberg.Image.aspect_ratio(image)
      assert aspect == 1.0
    end

    @tag :integration
    test "handles empty OCR text gracefully" do
      image =
        Kreuzberg.Image.new(
          "jpeg",
          ocr_text: ""
        )

      assert image.ocr_text == ""
      refute String.length(image.ocr_text) > 0
    end

    @tag :integration
    test "handles very long OCR text" do
      long_text = String.duplicate("A", 100_000)

      image =
        Kreuzberg.Image.new(
          "png",
          ocr_text: long_text
        )

      assert String.length(image.ocr_text) == 100_000
    end

    @tag :integration
    test "handles mixed case file sizes" do
      file_sizes = [0, 1, 1_000, 1_000_000, 10_000_000]

      Enum.each(file_sizes, fn size ->
        image = Kreuzberg.Image.new("jpeg", file_size: size)
        assert image.file_size == size
      end)
    end

    @tag :integration
    test "handles nil optional fields" do
      image = %Kreuzberg.Image{
        format: "png",
        data: nil,
        width: nil,
        height: nil,
        ocr_text: nil
      }

      assert image.format == "png"
      assert image.data == nil
      assert image.width == nil
      refute Kreuzberg.Image.has_data?(image)
    end
  end

  describe "Image struct completeness" do
    @tag :integration
    test "includes all fields in to_map" do
      image =
        Kreuzberg.Image.new(
          "png",
          width: 640,
          height: 480,
          dpi: 150,
          mime_type: "image/png",
          ocr_text: "test",
          page_number: 1,
          file_size: 5000
        )

      image_map = Kreuzberg.Image.to_map(image)

      assert Map.has_key?(image_map, "format")
      assert Map.has_key?(image_map, "width")
      assert Map.has_key?(image_map, "height")
      assert Map.has_key?(image_map, "dpi")
      assert Map.has_key?(image_map, "mime_type")
      assert Map.has_key?(image_map, "ocr_text")
      assert Map.has_key?(image_map, "page_number")
      assert Map.has_key?(image_map, "file_size")
    end

    @tag :integration
    test "restores all fields from map" do
      original_map = %{
        "format" => "jpeg",
        "width" => 1024,
        "height" => 768,
        "dpi" => 200,
        "mime_type" => "image/jpeg",
        "ocr_text" => "restored text",
        "page_number" => 2,
        "file_size" => 100_000
      }

      image = Kreuzberg.Image.from_map(original_map)

      assert image.format == "jpeg"
      assert image.width == 1024
      assert image.height == 768
      assert image.dpi == 200
      assert image.mime_type == "image/jpeg"
      assert image.ocr_text == "restored text"
      assert image.page_number == 2
      assert image.file_size == 100_000
    end
  end
end
