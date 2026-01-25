# frozen_string_literal: true

# Cross-language serialization tests for Ruby bindings
#
# Validates that ExtractionConfig serializes consistently with other language bindings

require 'json'
require 'spec_helper'

RSpec.describe Kreuzberg::ExtractionConfig do
  describe '#to_h' do
    it 'should serialize minimal config to hash' do
      config = Kreuzberg::ExtractionConfig.new
      hash = config.to_h

      expect(hash).to be_a(Hash)
      expect(hash).to have_key(:use_cache)
      expect(hash).to have_key(:enable_quality_processing)
      expect(hash).to have_key(:force_ocr)
    end

    it 'should serialize config with all fields' do
      config = Kreuzberg::ExtractionConfig.new(
        use_cache: true,
        enable_quality_processing: true,
        force_ocr: false
      )

      hash = config.to_h

      expect(hash[:use_cache]).to eq(true)
      expect(hash[:enable_quality_processing]).to eq(true)
      expect(hash[:force_ocr]).to eq(false)
    end

    it 'should preserve field values after serialization' do
      original = Kreuzberg::ExtractionConfig.new(
        use_cache: false,
        enable_quality_processing: true
      )

      hash = original.to_h

      expect(hash[:use_cache]).to eq(false)
      expect(hash[:enable_quality_processing]).to eq(true)
    end
  end

  describe '#to_json' do
    it 'should serialize to JSON' do
      config = Kreuzberg::ExtractionConfig.new(use_cache: true)
      json = config.to_json

      expect(json).to be_a(String)

      parsed = JSON.parse(json, symbolize_names: true)
      expect(parsed).to have_key(:use_cache)
      expect(parsed[:use_cache]).to eq(true)
    end

    it 'should produce valid JSON' do
      config = Kreuzberg::ExtractionConfig.new
      json = config.to_json

      expect { JSON.parse(json) }.not_to raise_error
    end

    it 'should use snake_case field names' do
      config = Kreuzberg::ExtractionConfig.new(use_cache: true)
      json = config.to_json

      expect(json).to include('use_cache')
      expect(json).not_to include('useCache')
    end
  end

  describe 'round-trip serialization' do
    it 'should survive serialization -> deserialization -> serialization' do
      config1 = Kreuzberg::ExtractionConfig.new(
        use_cache: true,
        enable_quality_processing: false
      )

      json1 = config1.to_json
      hash1 = JSON.parse(json1, symbolize_names: true)

      config2 = Kreuzberg::ExtractionConfig.new(hash1)
      json2 = config2.to_json

      # JSON strings should be equivalent
      expect(JSON.parse(json1)).to eq(JSON.parse(json2))
    end
  end

  describe 'field consistency' do
    it 'should include all mandatory fields' do
      config = Kreuzberg::ExtractionConfig.new
      hash = config.to_h

      mandatory_fields = [:use_cache, :enable_quality_processing, :force_ocr]
      mandatory_fields.each do |field|
        expect(hash).to have_key(field)
      end
    end

    it 'should handle nested ocr config' do
      config = Kreuzberg::ExtractionConfig.new(
        ocr: {
          backend: 'tesseract',
          language: 'eng'
        }
      )

      hash = config.to_h

      expect(hash).to have_key(:ocr)
      expect(hash[:ocr][:backend]).to eq('tesseract')
      expect(hash[:ocr][:language]).to eq('eng')
    end
  end

  describe 'immutability' do
    it 'should not modify original config during serialization' do
      config = Kreuzberg::ExtractionConfig.new(use_cache: true)

      json1 = config.to_json
      json2 = config.to_json
      json3 = config.to_json

      expect(json1).to eq(json2)
      expect(json2).to eq(json3)
    end
  end
end
