pipeline {
    agent any

    environment {
        NETLIFY_SITE_ID = '4cfa7aa8-e9c4-4f2f-9192-7b6c125a81cd'
        NETLIFY_AUTH_TOKEN = credentials('NETLIFT_PAT')
    }

    stages {

        stage('Clean') {
            steps {
                deleteDir()
                checkout scm
            }
        }

        stage('Build') {
            agent {
                docker {
                    image 'node:18'
                    reuseNode true
                }
            }

            steps {
                sh '''
                    npm ci --no-audit --no-fund
                    npm run build
                '''
            }
        }

        stage('Tests') {
            parallel {

                stage('Unit Tests') {
                    agent {
                        docker {
                            image 'node:18'
                            reuseNode true
                        }
                    }

                    steps {
                        sh '''
                            npm test -- --watchAll=false
                        '''
                    }

                    post {
                        always {
                            junit allowEmptyResults: true,
                                  testResults: 'jest-results/*.xml'
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
                            npx serve -s build -l 3000 &
                            SERVER_PID=$!

                            sleep 10

                            npx playwright test --reporter=html

                            kill $SERVER_PID || true
                        '''
                    }

                    post {
                        always {
                            publishHTML([
                                allowMissing: true,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: 'playwright-report',
                                reportFiles: 'index.html',
                                reportName: 'Local Playwright Report'
                            ])
                        }
                    }
                }
            }
        }

        stage('Stage Deploy') {
            agent {
                docker {
                    image 'node:18'
                    reuseNode true
                }
            }

            steps {
                sh '''
                    npx netlify-cli@20.1.1 deploy \
                        --site=$NETLIFY_SITE_ID \
                        --auth=$NETLIFY_AUTH_TOKEN \
                        --dir=build \
                        --json > deploy-output.json
                '''

                script {
                    env.STAGE_DEPLOY_URL = sh(
                        script: '''
                            node -e "console.log(JSON.parse(require('fs').readFileSync('deploy-output.json')).deploy_url)"
                        ''',
                        returnStdout: true
                    ).trim()

                    echo "Stage URL: ${env.STAGE_DEPLOY_URL}"
                }
            }
        }

        stage('Stage E2E') {
            agent {
                docker {
                    image 'mcr.microsoft.com/playwright:v1.39.0-jammy'
                    reuseNode true
                }
            }

            environment {
                CI_ENVIRONMENT_URL = "${STAGE_DEPLOY_URL}"
            }

            steps {
                sh '''
                    npx playwright test --reporter=html
                '''
            }

            post {
                always {
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'playwright-report',
                        reportFiles: 'index.html',
                        reportName: 'Stage Playwright Report'
                    ])
                }
            }
        }

        stage('Approval') {
            steps {
                timeout(time: 1, unit: 'MINUTES') {
                    input message: 'Deploy to Production?', ok: 'Deploy'
                }
            }
        }

        stage('Deploy') {
            agent {
                docker {
                    image 'node:18'
                    reuseNode true
                }
            }

            steps {
                sh '''
                    npx netlify-cli@20.1.1 deploy \
                        --site=$NETLIFY_SITE_ID \
                        --auth=$NETLIFY_AUTH_TOKEN \
                        --dir=build \
                        --prod
                '''
            }
        }

        stage('Production E2E') {
            agent {
                docker {
                    image 'mcr.microsoft.com/playwright:v1.39.0-jammy'
                    reuseNode true
                }
            }

            environment {
                CI_ENVIRONMENT_URL = 'https://glittery-heliotrope-717dbe.netlify.app'
            }

            steps {
                sh '''
                    npx playwright test --reporter=html
                '''
            }

            post {
                always {
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'playwright-report',
                        reportFiles: 'index.html',
                        reportName: 'Production Playwright Report'
                    ])
                }
            }
        }
    }
}