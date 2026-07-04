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
        stage('Checkout Infrastructure Code') {
            steps {
                checkout scm
                script {
                    echo " Creating dynamic terraform.tfvars file..."
                    // This generates the file directly in the Jenkins workspace securely
                    sh '''
                    cat << 'EOF' > terraform.tfvars
                    availability_zones   = ["ap-south-1a", "ap-south-1b"]
                    public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
                    private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
                    db_subnet_cidrs      = ["10.0.5.0/24", "10.0.6.0/24"]
                    key_name             = "sonarkey"
                    allowed_ssh_cidr     = "0.0.0.0/0"
                    db_password          = "YourSecureDBPassword123"
                    EOF
                    '''
                }
            }
        }
        
        stage('Provision AWS Infrastructure') {
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
                    
                    echo " DEPLOYMENT SUCCESSFUL!"
                    echo " SonarQube is now live. Access your dashboard here: http://${env.ALB_URL}"
                }
            }
        }
        
        stage('Destroy AWS Infrastructure') {
            when { 
                expression { params.ACTION == 'Destroy' } 
            }
            steps {
                script {
                    destroyInfra()
                }
            }
        }
    }
    
    post {
        always {
            // Clean up files for hygiene and security
            sh 'rm -f sonarkey.pem'
            sh 'rm -f terraform.tfvars'
        }
    }
}
