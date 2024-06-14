pipeline {
    agent {
        label 'docker'
    }

    options {
        timeout(time: 1, unit: 'HOURS')
    }

    triggers {
        cron('H */1 * * 1-5')
        pollSCM('H/10 * * * 1-5')
    }

    environment {
        AN_ACCESS_KEY = credentials('my-predefined-secret-text')
        PULL_REQUEST = "pr-${env.CHANGE_ID}"
        IMAGE_TAG = "${env.PULL_REQUEST}"
    }

    stages {
        stage('Summary') {
            steps {
                sh script: """
                    echo "GIT_BRANCH: ${GIT_BRANCH}"
                    echo "PULL_REQUEST: ${PULL_REQUEST}"
                """, label: "Details summary"
            }
        }

        stage('Static Analysis') {
            parallel {
                stage('Linting') {
                    agent {
                        dockerfile {
                            filename 'Dockerfile.custom'
                            dir 'ci'
                            label 'docker'
                        }
                    }
                    steps {
                        script {
                            sh "<run lint>"
                        }
                    }
                }
                stage('DevSecOps Static'){
                    steps {
                        echo "<run devsecops tests>"
                    }
                }
            }
        }

        stage('Build') {
            agent {
                docker {
                    image 'node:15.1.0-alpine3.10'
                    label 'docker'
                }
            }
            steps {
                sh "npm install"
                sh "npm run build"
                stash name: "DIST", includes: "dist/**"
                stash name: "NODE_MODULES", includes: "node_modules/**"
                archiveArtifacts artifacts: 'dist/**'
            }
        }


        stage('Test') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        unstash name: "NODE_MODULES"
                        sh "npm run test:unit"
                        junit 'tests/unit/reports/*.xml'
                    }
                }

                stage('Browser Tests') {
                    steps {
                        unstash name: "DIST"
                        unstash name: "NODE_MODULES"
                        sh "npm run test:cypress"
                        junit 'tests/cypress/reports/*.xml'
                    }
                }
            }
        }

        stage('Deploy') {
            agent {
                label "kubernetes"
            }
            when { 
                beforeAgent true
                allOf {
                    equals expected: 'master', actual: BRANCH_NAME
                    equals expected: 'SUCCESS', actual: currentBuild.currentResult
                }
            }
            steps {
                unstash name: "DIST"
                sh "docker build -t app:${env.GIT_COMMIT} ."
                sh "docker push app:${env.GIT_COMMIT}"
                script {
                    withCredentials([file(credentialsId: "K8S_CREDENTIALS", variable: 'KUBECTL_CONFIG_FILE')]) {
                        sh "kubectl apply --kubeconfig ${KUBECTL_CONFIG_FILE} -f deploy/template.yaml"
                    }
                }
            }
        }

        stage('DevSecOps Deploy'){
            steps {
                echo "<run devsecops tests>"
            }
        }

        stage('Integration tests') {
            when { 
                beforeAgent true
                allOf {
                    equals expected: 'master', actual: BRANCH_NAME
                    equals expected: 'SUCCESS', actual: currentBuild.currentResult
                }
            }
            steps {
                sh "<run int tests>"
                junit 'tests/integration/reports/*.xml'
            }
        }

    }

    post {
        success {
            emailext subject: "Pipeline successful", to: "devs@unir.net"
            cleanWs()
        }
        unstable {
            emailext subject: "Pipeline tests not successful", to: "devs@unir.net"
            cleanWs()
        }
        failure {
            emailext subject: "Pipeline error", to: "devops@unir.net,devs@unir.net"
            cleanWs()
        }
    }
}
