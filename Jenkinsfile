@Library('my-shared-library@main') _

pipeline {
    agent any

    parameters {
        choice(name: 'ACTION', choices: ['Apply', 'Destroy'], description: 'Choose to provision or destroy the infrastructure')
    }

    environment {
        // Fetches your AWS credentials securely
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
    }

    stages {
        stage('Clone Terraform + Ansible Repo') {
            steps {
                echo " Cloning Infrastructure Repository..."
                checkout scm
            }
        }

        stage('Terraform Init') {
            when { expression { params.ACTION == 'Apply' } }
            steps {
                echo "Initializing Terraform..."
                sh 'terraform init'
            }
        }

        stage('Terraform Validate') {
            when { expression { params.ACTION == 'Apply' } }
            steps {
                echo " Validating Terraform configuration..."
                sh 'terraform validate'
            }
        }

        stage('Terraform Plan') {
            when { expression { params.ACTION == 'Apply' } }
            steps {
                echo "Planning AWS Infrastructure..."
                sh 'terraform plan'
            }
        }

        stage('Terraform Apply') {
            when { expression { params.ACTION == 'Apply' } }
            steps {
                echo " Provisioning AWS Multi-Tier Infrastructure..."
                sh 'terraform apply -auto-approve'
                
                script {
                    // Dynamically extract the Bastion IP for the next stages
                    env.BASTION_IP = sh(script: 'terraform output -raw bastion_public_ip', returnStdout: true).trim()
                }
            }
        }

        stage('Update Ansible Inventory') {
            when { expression { params.ACTION == 'Apply' } }
            steps {
                echo " Preparing SSH Keys for Ansible..."
                withCredentials([file(credentialsId: 'sonarkey', variable: 'SSH_KEY_PATH')]) {
                    sh 'cp $SSH_KEY_PATH sonarkey.pem'
                    sh 'chmod 400 sonarkey.pem'
                }
            }
        }

        stage('Run Ansible Role') {
            when { expression { params.ACTION == 'Apply' } }
            steps {
                echo "Configuring SonarQube Server..."
                script {
                    // Calls your exact shared library function!
                    configureSonar(env.BASTION_IP)
                }
            }
        }

        stage('Terraform Destroy') {
            when { expression { params.ACTION == 'Destroy' } }
            steps {
                echo " Destroying AWS Infrastructure..."
                script {
                    // Calls your exact shared library function!
                    destroyInfra()
                }
            }
        }
    }

    post {
        always {
            // This automatically creates the "Declarative: Post Actions" stage in the UI
            echo " Cleaning up workspace to prevent security leaks..."
            sh 'rm -f sonarkey.pem terraform.tfvars'
            cleanWs()
        }
    }
}
