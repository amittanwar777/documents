pipeline {
    agent any
    stages {
        stage('Validate YAML') {
            steps {
                script {
                    def yamlFilePath = '/path/to/your/yaml/file.yml'
                    try {
                        def yaml = new org.yaml.snakeyaml.Yaml()
                        def inputStream = new FileInputStream(yamlFilePath)
                        yaml.load(inputStream)
                        println("YAML file is valid.")
                    } catch (org.yaml.snakeyaml.error.YAMLException e) {
                        println("YAML file is invalid: " + e.message)
                        error("YAML file is invalid.")
                    } catch (java.io.FileNotFoundException e) {
                        println("File not found: " + e.message)
                        error("YAML file not found.")
                    }
                }
            }
        }
    }
}
