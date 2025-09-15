pipeline {
    agent any

environment {
        PATH = "/usr/local/bin:/opt/homebrew/bin:/bin:/usr/bin:${env.PATH}"
        TERRAFORM_PATH = "/opt/homebrew/bin/terraform"
    }


    stages {
        stage('Checkout Code') {
            steps { checkout scm }
        }

        stage('Verify Tools') {
            steps {
                sh '''
                  echo "PATH=$PATH"
                  which sh || echo "sh not found"
                  which terraform || echo "terraform not found"
                  terraform -version || echo "terraform command failed"
                  which aws || echo "aws not found"
                  aws --version || echo "aws command failed"
                  which python3 || echo "python3 not found"
                  python3 --version || echo "python3 command failed"
                '''
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {
                    sh '''
                      set -e
                      echo "Initializing Terraform..."
                      terraform init -input=false
                      echo "Applying Terraform..."
                      terraform apply -auto-approve -input=false
                    '''
                }
            }
        }

        stage('Run Python ETL Script') {
            steps {
                sh '''
                  echo "Running ETL Python script..."
                  python3 my_script.py
                '''
            }
        }

        stage('Upload Output to S3') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {
                    sh '''
                      echo "Uploading transformed file to S3..."
                      aws s3 cp output/transformed.csv s3://curatedbts3/
                    '''
                }
            }
        }
    }

    post {
        success { echo 'Pipeline completed successfully ✅' }
        failure { echo 'Pipeline failed ❌' }
    }
}