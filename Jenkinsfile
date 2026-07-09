@Library('my-shared-library') _

pipeline {
    agent any

    parameters {
        choice(name: 'ACTION', choices: ['Apply', 'Destroy'], description: 'Select Apply to build or Destroy to wipe.')
    }

    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
        // Automatically injects your DB password into Terraform and Ansible!
        TF_VAR_db_password    = "YourSecureDBPassword123" 
    }

    stages {
        stage('Clone Terraform + Ansible Repo') {
            steps { checkout scm }
        }

        stage('Terraform Init') {
            when { expression { params.ACTION == 'Apply' } }
            steps { sh 'terraform init' }
        }

        stage('Terraform Validate') {
            when { expression { params.ACTION == 'Apply' } }
            steps { sh 'terraform validate' }
        }

        stage('Terraform Plan') {
            when { expression { params.ACTION == 'Apply' } }
            steps { sh 'terraform plan' }
        }

        stage('Terraform Apply') {
            when { expression { params.ACTION == 'Apply' } }
            steps {
                sh 'terraform apply -auto-approve'
                script {
                    env.BASTION_IP = sh(script: 'terraform output -raw bastion_public_ip', returnStdout: true).trim()
                    env.ALB_URL    = sh(script: 'terraform output -raw alb_dns_name', returnStdout: true).trim()
                }
            }
        }

        stage('Update Ansible Inventory') {
            when { expression { params.ACTION == 'Apply' } }
            steps { echo "Inventory updated securely via Dynamic AWS Plugin." }
        }

        stage('Run Ansible Role') {
            when { expression { params.ACTION == 'Apply' } }
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'sonarqube-ssh-key', keyFileVariable: 'SSH_KEY_PATH', usernameVariable: 'SSH_USER')]) {
                    script { configureSonar(env.BASTION_IP) }
                }
                echo " SonarQube is Live: http://${env.ALB_URL}"
            }
        }

        stage('Terraform Destroy') {
            when { expression { params.ACTION == 'Destroy' } }
            steps {
                script { destroyInfra() }
            }
        }
    }

    post {
        always {
            sh 'rm -f sonarkey.pem || true'
            cleanWs()
        }
        success {
            echo " Sending Success Email..."
            emailext (
                subject: " SUCCESS: Jenkins Pipeline - ${env.JOB_NAME} [${env.BUILD_NUMBER}]",
                body: """
                Great news! Your AWS Infrastructure pipeline completed successfully.
                
                Action Performed: ${params.ACTION}
                View the complete build logs here: ${env.BUILD_URL}
                """,
                to: "badliwalvikash@gmail.com" 
            )
        }
        failure {
            echo " Sending Failure Email..."
            emailext (
                subject: " FAILED: Jenkins Pipeline - ${env.JOB_NAME} [${env.BUILD_NUMBER}]",
                body: """
                Uh oh. The Jenkins pipeline failed during the ${params.ACTION} process.
                
                Please check the console logs to see what went wrong: ${env.BUILD_URL}
                """,
                to: "badliwalvikash@gmail.com" 
            )
        }
    }
}
