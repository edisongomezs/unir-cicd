pipeline {
    agent {
        label 'docker'
    }
    stages {
        stage('Source') {
            steps {
                git url: 'https://github.com/srayuso/unir-cicd.git', credentialsId: 'git-credentials-id'
            }
        }
        stage('Build') {
            steps {
                echo 'Building stage!'
                bat 'make build'
            }
        }
        stage('Unit tests') {
            steps {
                bat 'make test-unit'
                archiveArtifacts artifacts: 'results/unit_result.xml'
            }
        }
        stage('API tests') {
            steps {
                echo 'Running API tests!'
                bat 'make test-api'
                archiveArtifacts artifacts: 'results/api_result.xml'
            }
        }
        stage('E2E tests') {
            steps {
                echo 'Running E2E tests!'
                bat 'make test-e2e'
                archiveArtifacts artifacts: 'results/e2e/*.xml'
            }
        }
    }
    post {
        always {
            junit 'results/**/*.xml'
            cleanWs()
        }
        failure {
            script {
                def jobName = env.JOB_NAME
                def buildNumber = env.BUILD_NUMBER
                echo "Sending email notification for job ${jobName} build ${buildNumber}"
                emailext (
                    subject: "Pipeline error",
                    to: "edisonjaviergomezs@gmail.com,devs@unir.net",
                    body: "The job ${jobName} build ${buildNumber} has failed. Please check the Jenkins console for more details."
                )
            }
        }
        success {
            emailext (
                subject: "Pipeline successful",
                to: "devs@unir.net",
                body: "The pipeline has completed successfully. Great job!"
            )
        }
        unstable {
            emailext (
                subject: "Pipeline tests not successful",
                to: "devs@unir.net",
                body: "The pipeline has completed but some tests have failed. Please check the Jenkins console for more details."
            )
        }
    }
}
