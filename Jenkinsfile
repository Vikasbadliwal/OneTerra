@Library('my-shared-library') _

pipeline {
    agent any

    parameters {
        choice(name: 'ACTION', choices: ['Apply', 'Destroy'], description: 'Select Apply to build the project, or Destroy to wipe the AWS environment.')
    }

    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
    }

    stages {
        // Stage 1
        stage('Clone Terraform + Ansible Repo') {
            steps {
                checkout scm
                script {
                    echo " Creating dynamic terraform.tfvars file..."
                    writeFile file: 'terraform.tfvars', text: """
availability_zones   = ["ap-south-1a", "ap-south-1b"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
db_subnet_cidrs      = ["10.0.5.0/24", "10.0.6.0/24"]
key_name             = "sonarkey"
allowed_ssh_cidr     = "0.0.0.0/0"
db_password          = "YourSecureDBPassword123"
"""
                }
            }
        }

        // Stage 2
        stage('Terraform Init') {
            when { expression { params.ACTION == 'Apply' } }
            steps {
                sh 'terraform init'
            }
        }

        // Stage 3
        stage('Terraform Validate') {
            when { expression { params.ACTION == 'Apply' } }
            steps {
                sh 'terraform validate'
            }
        }

        // Stage 4
        stage('Terraform Plan') {
            when { expression { params.ACTION == 'Apply' } }
            steps {
                sh 'terraform plan'
            }
        }

        // Stage 5
        stage('Terraform Apply') {
            when { expression { params.ACTION == 'Apply' } }
            steps {
                sh 'terraform apply -auto-approve'
                script {
                    // Extract the outputs directly so we can pass them to Ansible
                    env.BASTION_IP = sh(script: 'terraform output -raw bastion_public_ip', returnStdout: true).trim()
                    env.ALB_URL    = sh(script: 'terraform output -raw alb_dns_name', returnStdout: true).trim()
                    
                    echo " AWS Provisioning Complete. Bastion IP: ${env.BASTION_IP}"
                }
            }
        }

        // Stage 6
        stage('Update Ansible Inventory') {
            when { expression { params.ACTION == 'Apply' } }
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'sonarqube-ssh-key', keyFileVariable: 'SSH_KEY_PATH', usernameVariable: 'SSH_USER')]) {
                    sh 'cp $SSH_KEY_PATH sonarkey.pem'
                    sh 'chmod 400 sonarkey.pem'
                }
            }
        }

        // Stage 7
        stage('Run Ansible Role') {
            when { expression { params.ACTION == 'Apply' } }
            steps {
                script {
                    // Using your shared library function
                    configureSonar(env.BASTION_IP)

                    echo " DEPLOYMENT SUCCESSFUL!"
                    echo " SonarQube is now live. Access your dashboard here: http://${env.ALB_URL}"
                }
            }
        }

        // Stage 8
        stage('Terraform Destroy') {
            when { expression { params.ACTION == 'Destroy' } }
            steps {
                script {
                    // Using your shared library function
                    destroyInfra()
                }
            }
        }
    }

    // Stage 9 (Automatically created by Jenkins as "Declarative: Post Actions")
    post {
        always {
            sh 'rm -f sonarkey.pem || true'
            sh 'rm -f terraform.tfvars || true'
            cleanWs()
        }
    }
}
