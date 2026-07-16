pipeline {
    agent any

    environment {
        NETLIFY_SITE_ID = '4cfa7aa8-e9c4-4f2f-9192-7b6c125a81cd'
        NETLIFY_AUTH_TOKEN = credentials('NETLIFT_PAT')
        REACT_APP_VERSION = "1.0.$BUILD_ID"
    }

    stages {

        // stage('Docker') {
        //     steps {
        //         sh 'docker build -t my-playwright .'
        //     }
        // }

        // stage('AWS') {
        //     agent {
        //         docker {
        //             image "amazon/aws-cli:2.35.23"
        //             args "--entrypoint=''"
        //         }
        //     }
        //     environment {
        //         S3_BUCKET="jenkins-bucket-363786805177-ap-south-1-an"
        //     }
        //     steps {
        //         withCredentials([usernamePassword(credentialsId: 'AWS_KEY', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
        //             sh '''
        //                 aws s3 ls
        //                 echo "Hello s2" > index.html
        //                 aws s3 cp index.html s3://${S3_BUCKET}/index.html
        //             '''
        //         }
        //     }
        // }

        stage('Build') {
            agent {
                docker {
                    image 'my-playwright'
                    reuseNode true
                }
            }
            steps {
                sh '''
                    ls -la
                    node --version
                    npm --version
                    rm -rf node_modules
                    npm ci
                    npm run build
                    ls -la
                '''
            }
        }

        stage('Tests') {
            parallel {
                stage('Unit tests') {
                    agent {
                        docker {
                            image 'my-playwright'
                            reuseNode true
                        }
                    }

                    steps {
                        sh '''
                            #test -f build/index.html
                            npm test
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
                            image 'my-playwright'
                            reuseNode true
                        }
                    }

                    steps {
                        sh '''
                            serve -s build &
                            sleep 10
                            npx playwright test  --reporter=html
                        '''
                    }

                    post {
                        always {
                            publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Local E2E', reportTitles: '', useWrapperFileDirectly: true])
                        }
                    }
                }
            }
        }

        stage('Deploy staging') {
            agent {
                docker {
                    image 'my-playwright'
                    reuseNode true
                }
            }

            environment {
                CI_ENVIRONMENT_URL = 'STAGING_URL_TO_BE_SET'
            }

            steps {
                sh '''
                    netlify --version
                    echo "Deploying to staging. Site ID: $NETLIFY_SITE_ID"
                    netlify status
                    netlify deploy --dir=build --json > deploy-output.json
                    CI_ENVIRONMENT_URL=$(jq -r '.deploy_url' deploy-output.json)
                    npx playwright test  --reporter=html
                '''
            }

            post {
                always {
                    publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Staging E2E', reportTitles: '', useWrapperFileDirectly: true])
                }
            }
        }

        stage('Deploy prod') {
            agent {
                docker {
                    image "amazon/aws-cli:2.35.23"
                    args "--entrypoint=''"
                }
            }

            environment {
                CI_ENVIRONMENT_URL = 'http://jenkins-bucket-363786805177-ap-south-1-an.s3-website.ap-south-1.amazonaws.com'
                S3_BUCKET="jenkins-bucket-363786805177-ap-south-1-an"
            }

            steps {
                withCredentials([usernamePassword(credentialsId: 'AWS_KEY', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                    sh '''
                        echo "Deploying to production. ${S3_BUCKET}"
                        aws s3 cp build s3://${S3_BUCKET}/ --recursive
                    '''
                }
            }

            post {
                always {
                    publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Prod E2E', reportTitles: '', useWrapperFileDirectly: true])
                }
            }
        }
        stage('Prod E2E') {
            agent {
                docker {
                    image "my-playwright"
                }
            }

            environment {
                CI_ENVIRONMENT_URL = 'http://jenkins-bucket-363786805177-ap-south-1-an.s3-website.ap-south-1.amazonaws.com'
            }

            steps {
                    sh '''
                        npx playwright test  --reporter=html
                    '''
            }

            post {
                always {
                    publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Prod E2E', reportTitles: '', useWrapperFileDirectly: true])
                }
            }
        }
    }
}
