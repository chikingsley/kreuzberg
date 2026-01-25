package dev.kreuzberg;

import static org.junit.jupiter.api.Assertions.*;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * Cross-language serialization tests for Java bindings.
 * 
 * Validates that ExtractionConfig serializes consistently with other language bindings.
 */
@DisplayName("ExtractionConfig Serialization")
class SerializationTest {

    private ObjectMapper objectMapper;

    @BeforeEach
    void setUp() {
        objectMapper = new ObjectMapper();
    }

    @Test
    @DisplayName("should serialize minimal config to JSON")
    void testMinimalSerialization() throws Exception {
        ExtractionConfig config = new ExtractionConfig();
        String json = objectMapper.writeValueAsString(config);

        assertNotNull(json);
        assertTrue(json.contains("useCache"));
        assertTrue(json.contains("enableQualityProcessing"));
        assertTrue(json.contains("forceOcr"));
    }

    @Test
    @DisplayName("should serialize config with custom values")
    void testCustomValuesSerialization() throws Exception {
        ExtractionConfig config = new ExtractionConfig();
        config.setUseCache(true);
        config.setEnableQualityProcessing(false);
        config.setForceOcr(true);

        String json = objectMapper.writeValueAsString(config);

        ExtractionConfig restored = objectMapper.readValue(json, ExtractionConfig.class);

        assertEquals(true, restored.isUseCache());
        assertEquals(false, restored.isEnableQualityProcessing());
        assertEquals(true, restored.isForceOcr());
    }

    @Test
    @DisplayName("should preserve field values after serialization")
    void testFieldPreservation() throws Exception {
        ExtractionConfig original = new ExtractionConfig();
        original.setUseCache(false);
        original.setEnableQualityProcessing(true);

        String json = objectMapper.writeValueAsString(original);
        ExtractionConfig restored = objectMapper.readValue(json, ExtractionConfig.class);

        assertEquals(original.isUseCache(), restored.isUseCache());
        assertEquals(original.isEnableQualityProcessing(), restored.isEnableQualityProcessing());
    }

    @Test
    @DisplayName("should handle round-trip serialization")
    void testRoundTripSerialization() throws Exception {
        ExtractionConfig config1 = new ExtractionConfig();
        config1.setUseCache(true);
        config1.setEnableQualityProcessing(false);

        String json1 = objectMapper.writeValueAsString(config1);
        ExtractionConfig config2 = objectMapper.readValue(json1, ExtractionConfig.class);
        String json2 = objectMapper.writeValueAsString(config2);

        // Should produce equivalent JSON
        ExtractionConfig parsed1 = objectMapper.readValue(json1, ExtractionConfig.class);
        ExtractionConfig parsed2 = objectMapper.readValue(json2, ExtractionConfig.class);

        assertEquals(parsed1.isUseCache(), parsed2.isUseCache());
        assertEquals(parsed1.isEnableQualityProcessing(), parsed2.isEnableQualityProcessing());
        assertEquals(parsed1.isForceOcr(), parsed2.isForceOcr());
    }

    @Test
    @DisplayName("should use camelCase field names")
    void testCamelCaseFieldNames() throws Exception {
        ExtractionConfig config = new ExtractionConfig();
        String json = objectMapper.writeValueAsString(config);

        assertTrue(json.contains("useCache"));
        assertTrue(json.contains("enableQualityProcessing"));
        assertTrue(json.contains("forceOcr"));

        assertFalse(json.contains("use_cache"));
        assertFalse(json.contains("enable_quality_processing"));
        assertFalse(json.contains("force_ocr"));
    }

    @Test
    @DisplayName("should serialize nested OCR config")
    void testNestedOcrConfig() throws Exception {
        ExtractionConfig config = new ExtractionConfig();
        OcrConfig ocrConfig = new OcrConfig();
        ocrConfig.setBackend("tesseract");
        ocrConfig.setLanguage("eng");
        config.setOcr(ocrConfig);

        String json = objectMapper.writeValueAsString(config);

        assertTrue(json.contains("\"ocr\""));
        assertTrue(json.contains("\"backend\""));
        assertTrue(json.contains("\"tesseract\""));
        assertTrue(json.contains("\"language\""));
        assertTrue(json.contains("\"eng\""));
    }

    @Test
    @DisplayName("should handle null values correctly")
    void testNullValueHandling() throws Exception {
        ExtractionConfig config = new ExtractionConfig();
        config.setOcr(null);
        config.setChunking(null);

        String json = objectMapper.writeValueAsString(config);
        ExtractionConfig restored = objectMapper.readValue(json, ExtractionConfig.class);

        assertNull(restored.getOcr());
        assertNull(restored.getChunking());
    }

    @Test
    @DisplayName("should maintain immutability during serialization")
    void testImmutabilityDuringSerialization() throws Exception {
        ExtractionConfig config = new ExtractionConfig();
        config.setUseCache(true);

        String json1 = objectMapper.writeValueAsString(config);
        String json2 = objectMapper.writeValueAsString(config);
        String json3 = objectMapper.writeValueAsString(config);

        assertEquals(json1, json2);
        assertEquals(json2, json3);
    }

    @Test
    @DisplayName("should serialize all mandatory fields")
    void testMandatoryFields() throws Exception {
        ExtractionConfig config = new ExtractionConfig();
        String json = objectMapper.writeValueAsString(config);

        ExtractionConfig parsed = objectMapper.readValue(json, ExtractionConfig.class);

        assertNotNull(parsed.isUseCache());
        assertNotNull(parsed.isEnableQualityProcessing());
        assertNotNull(parsed.isForceOcr());
    }

    @Test
    @DisplayName("should deserialize from JSON string")
    void testDeserialization() throws Exception {
        String json = "{\"useCache\":true,\"enableQualityProcessing\":false,\"forceOcr\":true}";

        ExtractionConfig config = objectMapper.readValue(json, ExtractionConfig.class);

        assertEquals(true, config.isUseCache());
        assertEquals(false, config.isEnableQualityProcessing());
        assertEquals(true, config.isForceOcr());
    }
}
