pipeline {
    agent any

    environment {
        TF_IN_AUTOMATION = 'true'
        AWS_DEFAULT_REGION = 'us-east-1'
        // Make sure terraform, aws, ansible are in PATH on Windows
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
                bat 'terraform init -no-color'
                bat 'type %BRANCH_NAME%.tfvars'
            }
        }

        stage('Terraform Plan') {
            steps {
                bat 'terraform plan -var-file=%BRANCH_NAME%.tfvars'
            }
        }

        /* ====== APPLY VALIDATION ====== */
        stage('Validate Apply') {
            input {
                message "Do you want to apply this Terraform plan?"
                ok "Apply"
            }
            steps {
                echo 'Terraform Apply Approved'
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

                    echo "Provisioned Instance IP: ${env.INSTANCE_IP}"
                    echo "Provisioned Instance ID: ${env.INSTANCE_ID}"

                    bat '''
                    echo [web] > dynamic_inventory.ini
                    echo %INSTANCE_IP% >> dynamic_inventory.ini
                    '''
                }
            }
        }

        stage('Wait for AWS Instance Health') {
            steps {
                echo "Waiting for instance ${env.INSTANCE_ID} to pass AWS health checks..."
                bat '''
                aws ec2 wait instance-status-ok ^
                --instance-ids %INSTANCE_ID% ^
                --region us-east-1
                '''
                echo "Instance is healthy. Proceeding to Ansible."
            }
        }

        /* ====== ANSIBLE VALIDATION ====== */
        stage('Validate Ansible') {
            input {
                message "Do you want to run Ansible?"
                ok "Run Ansible"
            }
            steps {
                echo 'Ansible Approved'
            }
        }

        stage('Ansible Configuration') {
            steps {
                bat '''
                where ansible-playbook
                ansible-playbook --version

                ansible-playbook install-monitoring.yml -i dynamic_inventory.ini
                '''
            }
        }

        /* ====== DESTROY VALIDATION ====== */
        stage('Validate Destroy') {
            input {
                message "Do you want to destroy the infrastructure?"
                ok "Destroy"
            }
            steps {
                echo 'Destroy Approved'
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
            bat 'del /f /q dynamic_inventory.ini 2>nul'
        }
        success {
            echo "✅ Pipeline completed successfully!"
        }
        failure {
            bat '''
            terraform destroy -auto-approve -var-file=%BRANCH_NAME%.tfvars || echo Cleanup failed or not required
            '''
        }
    }
}
