@Library('my-shared-library') _

pipeline {
    agent any
    
    // 1. ADD THIS BLOCK: Creates a dropdown menu in Jenkins
    parameters {
        choice(name: 'ACTION', choices: ['Apply', 'Destroy'], description: 'Select Apply to build the project, or Destroy to wipe the AWS environment.')
    }
    
    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
    }
    
    stages {
        stage('Checkout Infrastructure Code') {
            steps {
                checkout scm
            }
        }
        
        stage('Provision AWS Infrastructure') {
            // 2. ADD THIS CONDITION: Only runs if you select 'Apply'
            when { 
                expression { params.ACTION == 'Apply' } 
            }
            steps {
                script {
                    def infraData = provisionInfra()
                    
                    env.BASTION_IP = infraData.bastionIp
                    env.ALB_URL    = infraData.albUrl
                    
                    echo " AWS Provisioning Complete. Bastion IP: ${env.BASTION_IP}"
                }
            }
        }
        
        stage('Configure SonarQube via Ansible') {
            // Only runs if you select 'Apply'
            when { 
                expression { params.ACTION == 'Apply' } 
            }
            steps {
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'sonarqube-ssh-key', keyFileVariable: 'SSH_KEY_PATH', usernameVariable: 'SSH_USER')]) {
                        
                        sh 'cp $SSH_KEY_PATH sonarkey.pem'
                        sh 'chmod 400 sonarkey.pem'
                        
                        configureSonar(env.BASTION_IP)
                        
                        sh 'rm -f sonarkey.pem'
                    }
                    
                    // Moved the success message here so it only triggers on Apply
                    echo " DEPLOYMENT SUCCESSFUL!"
                    echo " SonarQube is now live. Access your dashboard here: http://${env.ALB_URL}"
                }
            }
        }
        
        stage('Destroy AWS Infrastructure') {
            // 3. THE DESTROY ROUTE: Only runs if you select 'Destroy'
            when { 
                expression { params.ACTION == 'Destroy' } 
            }
            steps {
                script {
                    // Calls the new function from your shared library
                    destroyInfra()
                }
            }
        }
    }
    
    post {
        always {
            // Ensure the SSH key is deleted even if the pipeline fails or is cancelled
            sh 'rm -f sonarkey.pem'
        }
    }
}
