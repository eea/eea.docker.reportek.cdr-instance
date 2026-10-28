def notifyBuild() {
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

pipeline {
  agent {
    node { label 'docker-host' }
  }

  options {
    disableConcurrentBuilds()
    timeout(time: 60, unit: 'MINUTES')
    buildDiscarder(logRotator(numToKeepStr: '20'))
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
    // a release is a tag in this form: <Zope minor>-<N>, ex: 5.14-3
    TAG_PATTERN = '^[0-9]+[.][0-9]+-[0-9]+$'
    // pinned, the scan results should not change because the scanner did
    TRIVY_IMAGE = "aquasec/trivy:0.76.0"
    TEST_IMAGE = "cdr-testing:${SAFE_BUILD_TAG}"
    GITFLOW_CONTAINER = "${SAFE_BUILD_TAG}-gitflow"
  }

  // How a release happens: the release (and its tag) is created by the base image pipeline, when it points
  // the Dockerfile to a new base image. The tag is then built here, and Release publishes <zope>-<N> and latest.
  // Commits made directly on master are built and tested, but not released until they are tagged.
  // Tags that are not a release (ex: the old z5-*) are ignored.
  stages {

    stage('Build image') {
      when {
        expression { !env.TAG_NAME || env.TAG_NAME ==~ env.TAG_PATTERN }
      }
      steps {
        sh '''docker build --pull --platform=linux/amd64 --label "org.opencontainers.image.revision=$GIT_COMMIT" --label "org.opencontainers.image.source=https://github.com/eea/$GIT_NAME" --label "org.opencontainers.image.version=${TAG_NAME:-$BRANCH_NAME}" -t "$TEST_IMAGE" .'''
      }
    }

    // Start the image that was just built and check that it serves, before anything is published.
    stage('Smoke test') {
      when {
        expression { !env.TAG_NAME || env.TAG_NAME ==~ env.TAG_PATTERN }
      }
      steps {
        sh '''SMOKE_PLATFORM=linux/amd64 ./test/smoke.sh "$TEST_IMAGE"'''
      }
    }

    // Trivy, on the image that was just built. Fixable CRITICAL vulnerabilities fail the build, the HIGH ones are only
    // listed (some of them are not fixed upstream, and there are fixable ones today). Findings can be accepted in
    // a .trivyignore file in the root of the repository. When the scan cannot run (ex: the vulnerability database
    // cannot be downloaded) the build is marked unstable, a Docker Hub or ghcr.io outage should not block a release.
    // The image is scanned from a tar file, so the Docker socket is not given to the scanner.
    stage('Scan image') {
      when {
        expression { !env.TAG_NAME || env.TAG_NAME ==~ env.TAG_PATTERN }
      }
      options {
        timeout(time: 15, unit: 'MINUTES')
      }
      steps {
        script {
          def rc = 1
          try {
            rc = sh(returnStatus: true, script: '''
              docker save -o image.tar "$TEST_IMAGE"
              # no bind mount: the agent runs in a container, so its workspace path does not exist for the docker daemon
              scan() {
                cid=$(docker create -v trivy-cache:/root/.cache "$TRIVY_IMAGE" image --quiet --input /tmp/image.tar --scanners vuln "$@" --table-mode detailed)
                docker cp image.tar "$cid:/tmp/image.tar"
                rc=0
                docker start -a "$cid" || rc=$?
                docker rm -v "$cid" > /dev/null
                return $rc
              }
              scan --severity HIGH,CRITICAL --ignore-unfixed
              scan --severity CRITICAL --ignore-unfixed --exit-code 10
            ''')
          } finally {
            sh(returnStatus: true, script: '''rm -f image.tar''')
          }
          if (rc == 10) {
            error "Trivy found fixable CRITICAL vulnerabilities in the image, see the list above"
          } else if (rc != 0) {
            unstable "Trivy could not scan the image (exit code ${rc})"
          }
        }
      }
    }

    // Publish the image that was just built and tested from the tag. latest only moves to the newest release,
    // so rebuilding an old tag does not take it backwards. The GitHub release already exists, it was created with the tag.
    stage('Release') {
      when {
        expression { (env.TAG_NAME ?: '') ==~ env.TAG_PATTERN }
      }
      steps {
        withCredentials([usernamePassword(credentialsId: 'jekinsdockerhub', usernameVariable: 'DOCKERHUB_USER', passwordVariable: 'DOCKERHUB_PASS')]) {
          script {
            try {
              sh '''
                set -e
                VERSION="$TAG_NAME"
                git fetch -q --force "https://github.com/eea/$GIT_NAME.git" "refs/tags/*:refs/tags/*"
                # a tag only releases what is on master, anybody with write access can push a tag
                if [ "$(git rev-parse --is-shallow-repository)" = "true" ]; then git fetch -q --unshallow "https://github.com/eea/$GIT_NAME.git" master; else git fetch -q "https://github.com/eea/$GIT_NAME.git" master; fi
                if ! git merge-base --is-ancestor HEAD FETCH_HEAD; then
                  echo "The commit tagged $VERSION is not on master, not releasing it"
                  exit 1
                fi
                echo "Releasing $DOCKERHUB_REPO:$VERSION"
                printf '%s' "$DOCKERHUB_PASS" | docker login -u "$DOCKERHUB_USER" --password-stdin
                docker tag "$TEST_IMAGE" "$DOCKERHUB_REPO:$VERSION"
                docker push "$DOCKERHUB_REPO:$VERSION"
                NEWEST=$(git tag | grep -E "$TAG_PATTERN" | sort -V | tail -n 1)
                if [ "$NEWEST" = "$VERSION" ]; then
                  docker tag "$TEST_IMAGE" "$DOCKERHUB_REPO:latest"
                  docker push "$DOCKERHUB_REPO:latest"
                else
                  echo "$VERSION is not the newest release ($NEWEST), latest is left alone"
                fi
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
    // Only the newest release updates the chart, and the chart is left alone when its appVersion is not
    // older than the released one.
    stage('Update helm chart') {
      when {
        expression { (env.TAG_NAME ?: '') ==~ env.TAG_PATTERN }
      }
      options {
        timeout(time: 15, unit: 'MINUTES')
      }
      steps {
        withCredentials([string(credentialsId: 'eea-jenkins-token', variable: 'GIT_TOKEN')]) {
          sh '''
            set -e
            docker pull eeacms/gitflow
            docker run -i --rm --name="$GITFLOW_CONTAINER-helm" -e GIT_TOKEN -e GIT_NAME="$GIT_NAME" -e DOCKERHUB_REPO="$DOCKERHUB_REPO" -e HELM_CHART="$HELM_CHART" -e VERSION="$TAG_NAME" -e GIT_AUTHOR_NAME="EEA Jenkins" -e GIT_AUTHOR_EMAIL="eea-jenkins@users.noreply.github.com" -e GIT_COMMITTER_NAME="EEA Jenkins" -e GIT_COMMITTER_EMAIL="eea-jenkins@users.noreply.github.com" --entrypoint bash eeacms/gitflow -s <<'SCRIPT'
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
      // the images built here are not needed once the build is over
      sh '''
        docker rmi "$TEST_IMAGE" > /dev/null 2>&1 || true
        if [ -n "${TAG_NAME:-}" ]; then
          docker rmi "$DOCKERHUB_REPO:$TAG_NAME" > /dev/null 2>&1 || true
          docker rmi "$DOCKERHUB_REPO:latest" > /dev/null 2>&1 || true
        fi
      '''
      cleanWs(cleanWhenAborted: true, cleanWhenFailure: true, cleanWhenNotBuilt: true, cleanWhenSuccess: true, cleanWhenUnstable: true, deleteDirs: true)
    }
    // a new tag is a new job without a previous build, so report every failure instead of only the changes
    failure {
      script { notifyBuild() }
    }
    unstable {
      script { notifyBuild() }
    }
    fixed {
      script { notifyBuild() }
    }
  }
}
