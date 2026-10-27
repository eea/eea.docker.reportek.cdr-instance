pipeline {
  agent {
    node { label 'docker-host' }
  }

  options {
    disableConcurrentBuilds()
  }

  environment {
    // per-build docker config, so registry logins are not written to the agent's shared ~/.docker
    DOCKER_CONFIG = "${WORKSPACE}/.docker"
    // BUILD_TAG has %2f for a / in the branch name, keep only what docker accepts in tags and names
    SAFE_BUILD_TAG = "${env.BUILD_TAG.toLowerCase().replaceAll('[^a-z0-9_.-]', '-')}"
    GIT_NAME = "eea.docker.reportek.cdr-instance"
    DOCKERHUB_REPO = "eeacms/reportek-cdr"
    // only the Zope 5 chart follows these images, the old cdr and bdr charts must stay untouched
    HELM_CHART = "cdr-py3"
    TEST_IMAGE = "cdr-testing:${SAFE_BUILD_TAG}"
    GITFLOW_CONTAINER = "${SAFE_BUILD_TAG}-gitflow"
  }

  stages {

    stage('Build image') {
      steps {
        sh '''docker build --pull --platform=linux/amd64 -t "$TEST_IMAGE" .'''
      }
    }

    // Publish the image that was just built, then let gitflow tag it and create the GitHub release.
    // The image has to be on Docker Hub first, gitflow only waits for it (TAG_ONLY).
    // The release version follows the base image (<zope>-<N>), so nothing is released until the
    // Dockerfile points to a base image tagged in that form.
    stage('Release') {
      when {
        branch 'master'
      }
      steps {
        withCredentials([string(credentialsId: 'eea-jenkins-token', variable: 'GIT_TOKEN'), usernamePassword(credentialsId: 'jekinsdockerhub', usernameVariable: 'DOCKERHUB_USER', passwordVariable: 'DOCKERHUB_PASS')]) {
          script {
            try {
              sh '''
                set -e
                rm -f .released-version
                git fetch -q --force "https://github.com/eea/$GIT_NAME.git" "refs/tags/*:refs/tags/*"
                if [ -n "$(git tag --points-at HEAD)" ]; then
                  echo "This commit is already released as $(git tag --points-at HEAD | head -n 1), nothing to do"
                  exit 0
                fi
                if ! VERSION=$(./src/docker/calculate_next_release.sh); then
                  echo "No release: the base image in the Dockerfile is not tagged as <zope>-<N> yet"
                  exit 0
                fi
                echo "Releasing $DOCKERHUB_REPO:$VERSION"
                echo "$VERSION" > .released-version
                printf '%s' "$DOCKERHUB_PASS" | docker login -u "$DOCKERHUB_USER" --password-stdin
                docker tag "$TEST_IMAGE" "$DOCKERHUB_REPO:$VERSION"
                docker tag "$TEST_IMAGE" "$DOCKERHUB_REPO:latest"
                docker push "$DOCKERHUB_REPO:$VERSION"
                docker push "$DOCKERHUB_REPO:latest"
                docker pull eeacms/gitflow
                docker run -i --rm --name="$GITFLOW_CONTAINER" -e GIT_BRANCH="master" -e GIT_NAME="$GIT_NAME" -e DOCKERHUB_REPO="$DOCKERHUB_REPO" -e GIT_TOKEN -e DOCKERHUB_USER -e DOCKERHUB_PASS -e GITFLOW_BEHAVIOR="TAG_ONLY" eeacms/gitflow
              '''
            } finally {
              sh '''docker logout || true'''
            }
          }
        }
      }
    }

    // Point the Zope 5 helm chart (appVersion) to the version that was just released, and release the chart
    // the same way it is done by hand: Chart.yaml, README, docs/ package and index, pushed to helm-charts.
    // Deliberately not using gitflow's add_helm_chart_entry.sh, it also updates eea-fleet (rolls the
    // change out to every environment) and the charts depending on this one.
    // Only runs when the Release stage published a version. The chart is left alone when its
    // appVersion is not older than the released one.
    stage('Update helm chart') {
      when {
        allOf {
          branch 'master'
          expression { fileExists('.released-version') }
        }
      }
      options {
        timeout(time: 15, unit: 'MINUTES')
      }
      steps {
        withCredentials([string(credentialsId: 'eea-jenkins-token', variable: 'GIT_TOKEN')]) {
          sh '''
            set -e
            docker pull eeacms/gitflow
            docker run -i --rm --name="$GITFLOW_CONTAINER-helm" -e GIT_TOKEN -e GIT_NAME="$GIT_NAME" -e DOCKERHUB_REPO="$DOCKERHUB_REPO" -e HELM_CHART="$HELM_CHART" -e VERSION="$(cat .released-version)" -e GIT_AUTHOR_NAME="EEA Jenkins" -e GIT_AUTHOR_EMAIL="eea-jenkins@users.noreply.github.com" -e GIT_COMMITTER_NAME="EEA Jenkins" -e GIT_COMMITTER_EMAIL="eea-jenkins@users.noreply.github.com" --entrypoint bash eeacms/gitflow -s <<'SCRIPT'
            set -e
            . /common_functions
            git clone -q "https://eea-jenkins:$GIT_TOKEN@github.com/eea/helm-charts.git"
            cd helm-charts
            old=$(yq -r '.appVersion' "sources/$HELM_CHART/Chart.yaml")
            if [ "$(is_smaller "$old" "$VERSION")" != "True" ]; then
              echo "$HELM_CHART appVersion $old is not older than $VERSION, nothing to update"
              exit 0
            fi
            yq -i '.appVersion = strenv(VERSION)' "sources/$HELM_CHART/Chart.yaml"
            export HELM_VERSION_TYPE=PATCH
            export HELM_UPGRADE_MESSAGE="Automated release of [$DOCKERHUB_REPO:$VERSION](https://github.com/eea/$GIT_NAME/releases)"
            export HELM_COMMIT_MESSAGE="Auto release of $DOCKERHUB_REPO:$VERSION"
            (cd "sources/$HELM_CHART" && ../../increase_version_helm.sh)
            CI=yes ./update_docs.sh "$HELM_CHART"
SCRIPT
          '''
        }
      }
    }

  }

  post {
    always {
      cleanWs(cleanWhenAborted: true, cleanWhenFailure: true, cleanWhenNotBuilt: true, cleanWhenSuccess: true, cleanWhenUnstable: true, deleteDirs: true)
    }
    changed {
      script {
        def details = """<h1>${env.JOB_NAME} - Build #${env.BUILD_NUMBER} - ${currentBuild.currentResult}</h1>
                         <p>Check console output at <a href="${env.BUILD_URL}/display/redirect">${env.JOB_BASE_NAME} - #${env.BUILD_NUMBER}</a></p>
                      """
        emailext(
        subject: '$DEFAULT_SUBJECT',
        body: details,
        attachLog: true,
        compressLog: true,
        to: 'eea-edw-c-team-alerts@googlegroups.com',
        recipientProviders: [[$class: 'DevelopersRecipientProvider'], [$class: 'CulpritsRecipientProvider']]
        )
      }
    }
  }
}
