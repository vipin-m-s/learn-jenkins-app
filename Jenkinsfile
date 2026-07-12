pipeline {
    agent any
    stages {
        stage('w/o docker') {
            steps {
                sh '''
                    echo without docker...
                    ls -ltra
                    touch no_container.txt
                    ls -ltra
                '''
            }
        }
        stage('with docker') {
            agent {
                docker {
                    image 'node:18-alpine'
                    reuseNode true
                }
            }
            steps {
                sh '''
                    echo with docker...
                    ls -ltra
                    touch container.txt
                    ls -ltra
                '''
            }
        }
    }
}