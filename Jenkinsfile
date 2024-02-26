pipeline {
    
    agent any
    
    environment {
        CONFLUENT_CLOUD_API_KEY = credentials('confluent-cloud-api-key')
        CONFLUENT_CLOUD_API_SECRET = credentials('confluent-cloud-api-secret')
        TF_IN_AUTOMATION = 'true'
    }
    
    stages {

        stage('Init') {
            steps {
                sh '''
                terraform init -no-color -migrate-state
                '''
            }
        }
        
        stage('Plan') {
            steps {
                sh '''
                terraform plan -no-color
                '''
            }
        }

        stage('Confirmation') {
            steps {
                input 'Do you want to apply the changes?'
            }
        }

        stage('Apply') {
            steps {
                sh '''
                terraform apply -auto-approve -no-color
                '''
            }
        }
    }
}