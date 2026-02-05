val privatePropertiesFile = file("private-gradle.properties")
if (privatePropertiesFile.exists()) {
    privatePropertiesFile.reader().use {
        val properties = java.util.Properties()
        properties.load(it)
        properties.forEach { (key, value) ->
            project.extensions.extraProperties[key.toString()] = value
        }
    }
}