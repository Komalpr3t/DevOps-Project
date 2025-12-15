pipeline {
    agent any

    environment {
        TF_IN_AUTOMATION = 'true'
    }

    stages {
        stage('Init') {
            steps {
                bat 'dir'
                bat 'terraform init -no-color'
            }
        }
    }
}
