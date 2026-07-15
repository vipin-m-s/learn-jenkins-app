pipeline {
    agent any

    environment {
        NETLIFY_SITE_ID = "4cfa7aa8-e9c4-4f2f-9192-7b6c125a81cd"
        NETLIFY_AUTH_TOKEN = credentials('NETLIFT_PAT')
    }

    stages {
        stage('Build') {
            agent {
                docker {
                    image 'node:18-alpine'
                    reuseNode true
                }
            }
            steps {
                sh '''
                    npm cache clean --force
                    rm -rf node_modules
                    rm -rf .npm
                    npm install --no-audit --no-fund
                    npm run build
                '''
            }
        }
        stage('Test') {
            parallel {
                stage('Unit Tests') {
                    agent {
                        docker {
                            image 'node:18-alpine'
                            reuseNode true
                        }
                    }
                    steps {
                        sh '''
                            ls -ltra
                            test -f build/index.html
                            npm test
                            ls -ltra
                        '''
                    }
                    post {
                        always {
                            junit 'jest-results/junit.xml'
                        }
                    }
                }
                stage('E2E') {
                    agent {
                        docker {
                            image 'mcr.microsoft.com/playwright:v1.39.0-jammy'
                            reuseNode true
                        }
                    }
                    steps {
                        sh '''
                            npx serve -s build &
                            sleep 10
                            npx playwright test --reporter=html
                        '''
                    }
                    post {
                        always {
                            publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, icon: '', keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Playwright HTML Report', reportTitles: '', useWrapperFileDirectly: true])
                        }
                    }
                }
            }
        }

        stage('Deploy prod') {
            agent {
                docker {
                    image 'node:18-alpine'
                    reuseNode true
                }
            }
            steps {
                sh '''
                npm install -g netlify-cli@20.1.1
                node_modules/.bin/netlify --version
                echo "deploying to prod.... ${NETLIFY_SITE_ID}"
                node_modules/.bin/netlify status
                node_modules/.bin/netlify deploy --dir=build --prod
                '''
                
            }
        }
        stage('Post deploy test') {
            agent {
                docker {
                    image 'node:18-alpine'
                    reuseNode true
                }
            }
            environment {
                CI_ENVIRONMENT_URL="https://glittery-heliotrope-717dbe.netlify.app"
            }
            steps {
                sh '''
                    npx playwright test --reporter=html
                '''
                
            }
        }
    }
    post {
        always {
            cleanWs()
        }
    }
}