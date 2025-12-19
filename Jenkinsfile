pipeline {
    agent any

    environment {
        TF_IN_AUTOMATION   = 'true'
        TF_CLI_ARGS        = '-no-color'
        AWS_DEFAULT_REGION = 'us-east-1'
        PATH = "C:\\Program Files\\Amazon\\AWSCLIV2;C:\\Terraform;C:\\Python312;${env.PATH}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                bat '''
                terraform init -no-color
                type %BRANCH_NAME%.tfvars
                '''
            }
        }

        stage('Terraform Plan') {
            steps {
                bat 'terraform plan -var-file=%BRANCH_NAME%.tfvars'
            }
        }

        /* ===== APPLY APPROVAL ===== */
        stage('Validate Apply') {
            steps {
                input message: "Do you want to apply this Terraform plan?",
                      ok: "Apply"
            }
        }

        stage('Terraform Apply') {
            steps {
                script {
                    bat 'terraform apply -auto-approve -var-file=%BRANCH_NAME%.tfvars'

                    env.INSTANCE_IP = bat(
                        script: 'terraform output -raw instance_public_ip',
                        returnStdout: true
                    ).trim()

                    env.INSTANCE_ID = bat(
                        script: 'terraform output -raw instance_id',
                        returnStdout: true
                    ).trim()

                    bat '''
                    echo [web] > dynamic_inventory.ini
                    echo %INSTANCE_IP% >> dynamic_inventory.ini
                    '''
                }
            }
        }

        stage('Wait for AWS Instance Health') {
            steps {
                bat '''
                aws ec2 wait instance-status-ok ^
                  --instance-ids %INSTANCE_ID% ^
                  --region %AWS_DEFAULT_REGION%
                '''
            }
        }

        /* ===== ANSIBLE APPROVAL (DEV ONLY) ===== */
        stage('Validate Ansible') {
            when {
                branch 'dev'
            }
            steps {
                input message: "Do you want to run Ansible?",
                      ok: "Run Ansible"
            }
        }

        stage('Ansible Configuration') {
            steps {
                ansiblePlaybook(
                    playbook: 'grafana.yml',
                    inventory: 'dynamic_inventory.ini',
                    credentialsId: 'SSH_CREDENTIALS_ID'
                )
                ansiblePlaybook(
                    playbook: 'test-grafana.yml',
                    inventory: 'dynamic_inventory.ini',
                    credentialsId: 'SSH_CREDENTIALS_ID'
                )
            }
        }

        /* ===== DESTROY APPROVAL ===== */
        stage('Validate Destroy') {
            steps {
                input message: "Do you want to destroy the infrastructure?",
                      ok: "Destroy"
            }
        }

        stage('Terraform Destroy') {
            steps {
                bat 'terraform destroy -auto-approve -var-file=%BRANCH_NAME%.tfvars'
            }
        }
    }

    post {
        always {
            bat 'if exist dynamic_inventory.ini del /f /q dynamic_inventory.ini'
        }
        failure {
            bat 'terraform destroy -auto-approve -var-file=%BRANCH_NAME%.tfvars || echo Cleanup failed'
        }
        aborted {
            bat 'terraform destroy -auto-approve -var-file=%BRANCH_NAME%.tfvars || echo Cleanup failed'
        }
        success {
            echo '✅ Pipeline completed successfully!'
        }
    }
}
