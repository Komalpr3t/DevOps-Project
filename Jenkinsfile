pipeline {
    agent any
   environment {
    TF_IN_AUTOMATION = 'true'
    TF_CLI_ARGS = '-no-color'
    AWS_DEFAULT_REGION = 'us-east-1'
    PATH = "/usr/local/bin:/opt/homebrew/bin:/Users/vyshu/Library/Python/3.12/bin:${env.PATH}"
    // CHANGE THIS: Replace 'main' with your actual .tfvars filename (e.g., 'dev' or 'prod')
    BRANCH_NAME = "main" 
}
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                sh 'terraform init -no-color'
                // Use double quotes to allow variable interpolation
                sh "cat ${env.BRANCH_NAME}.tfvars"
            }
        }

        stage('Terraform Plan') {
            steps {
                sh "terraform plan -var-file=${env.BRANCH_NAME}.tfvars"
            }
        }

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
                    // FIX: Changed to double quotes so $BRANCH_NAME works
                    sh "terraform apply -auto-approve -var-file=${env.BRANCH_NAME}.tfvars"

                    env.INSTANCE_IP = sh(
                        script: 'terraform output -raw instance_public_ip',
                        returnStdout: true
                    ).trim()

                    env.INSTANCE_ID = sh(
                        script: 'terraform output -raw instance_id',
                        returnStdout: true
                    ).trim()

                    sh """
                    echo "[web]" > dynamic_inventory.ini
                    echo "${env.INSTANCE_IP}" >> dynamic_inventory.ini
                    """
                }
            }
        }

        stage('Wait for AWS Instance Health') {
            steps {
                sh "aws ec2 wait instance-status-ok --instance-ids ${env.INSTANCE_ID} --region us-east-1"
            }
        }

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
                sh 'ansible-playbook install-monitoring.yml -i dynamic_inventory.ini'
            }
        }

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
                sh "terraform destroy -auto-approve -var-file=${env.BRANCH_NAME}.tfvars"
            }
        }
    }

    post {
        always {
            sh 'rm -f dynamic_inventory.ini'
        }
        failure {
            // FIX: Ensure this also uses double quotes
            sh "terraform destroy -auto-approve -var-file=${env.BRANCH_NAME}.tfvars || echo 'Cleanup failed or not necessary.'"
        }
    }
}