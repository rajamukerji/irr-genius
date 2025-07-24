package com.irrgenius.android.data.models

data class GrowthPoint(
    val month: Int,
    val value: Double
) {
    companion object {
        /**
         * Creates a list of GrowthPoint from JSON string
         */
        fun fromJsonString(json: String?): List<GrowthPoint> {
            if (json.isNullOrEmpty()) return emptyList()
            
            return try {
                // Simple JSON parsing for GrowthPoint arrays
                val cleanJson = json.trim()
                if (!cleanJson.startsWith("[") || !cleanJson.endsWith("]")) return emptyList()
                
                val content = cleanJson.substring(1, cleanJson.length - 1).trim()
                if (content.isBlank()) return emptyList()
                
                // Split by objects (assuming format like [{"month":1,"value":100.0},{"month":2,"value":200.0}])
                val objects = mutableListOf<String>()
                var braceCount = 0
                var currentObject = StringBuilder()
                
                for (char in content) {
                    when (char) {
                        '{' -> {
                            braceCount++
                            currentObject.append(char)
                        }
                        '}' -> {
                            braceCount--
                            currentObject.append(char)
                            if (braceCount == 0) {
                                objects.add(currentObject.toString())
                                currentObject.clear()
                            }
                        }
                        ',' -> {
                            if (braceCount == 0) {
                                // Skip comma between objects
                            } else {
                                currentObject.append(char)
                            }
                        }
                        else -> {
                            if (braceCount > 0) {
                                currentObject.append(char)
                            }
                        }
                    }
                }
                
                return objects.mapNotNull { parseGrowthPoint(it) }
            } catch (e: Exception) {
                emptyList()
            }
        }
        
        private fun parseGrowthPoint(jsonObject: String): GrowthPoint? {
            return try {
                // Parse simple JSON object like {"month":1,"value":100.0}
                val monthMatch = Regex("\"month\"\\s*:\\s*(\\d+)").find(jsonObject)
                val valueMatch = Regex("\"value\"\\s*:\\s*([\\d.]+)").find(jsonObject)
                
                if (monthMatch != null && valueMatch != null) {
                    val month = monthMatch.groupValues[1].toInt()
                    val value = valueMatch.groupValues[1].toDouble()
                    GrowthPoint(month, value)
                } else null
            } catch (e: Exception) {
                null
            }
        }
        
        /**
         * Converts a list of GrowthPoint to JSON string
         */
        fun toJsonString(growthPoints: List<GrowthPoint>): String {
            return try {
                if (growthPoints.isEmpty()) return "[]"
                
                val jsonObjects = growthPoints.map { point ->
                    "{\"month\":${point.month},\"value\":${point.value}}"
                }
                
                "[${jsonObjects.joinToString(",")}]"
            } catch (e: Exception) {
                "[]"
            }
        }
    }
    
    /**
     * Validates the growth point data
     */
    fun validate(): Boolean {
        return month >= 0 && value.isFinite()
    }
}