# Releasing the CDR image

`eeacms/reportek-cdr` is released by Jenkins, a release is a tag `<zope minor>-<N>` (ex: `5.14-3`) and `latest`.
Docker Hub autobuilds are not used.

The release follows the base image (`eeacms/reportek-base-dr`):

1. When a new base image is released, its pipeline points the `FROM` line of the `Dockerfile` to it and creates the
   GitHub release here, which creates the tag. The version is the Zope minor of the base image and the next free
   number of this repository, so it is not the same number as the base image.
2. The tag build builds the image, runs a smoke test (the container starts and answers) and a Trivy scan.
3. **Release** pushes `<version>` and `latest` (`latest` only for the newest release).
4. **Update helm chart** sets `appVersion` of the `cdr-py3` chart in `eea/helm-charts` to the new version and releases the
   chart (patch version, `docs/` package and index). Only the Zope 5 chart is touched, nothing is changed in `eea-fleet`,
   so the new version is not rolled out to the environments by this. The chart is left alone when its `appVersion` is
   already the same or newer.

## Releasing something that was committed directly to `master`

A commit on `master` is built and tested, but not released. To release it, create the GitHub release for the next
version, which creates the tag, and Jenkins publishes the image:

```
VERSION=$(./src/docker/calculate_next_release.sh)
gh release create "$VERSION" --repo eea/eea.docker.reportek.cdr-instance --target master --title "$VERSION" --notes "Release $VERSION"
```

Only tags like `<zope minor>-<N>` (ex: `5.14-3`) release anything, and only when the tagged commit is on `master`.
Tag creation should be restricted to the Jenkins user and the admins (GitHub ruleset), a tag is a release.

## When something fails

- **The tag build failed after the tag exists:** the tag has no image (or no helm chart update). Re-run the build of
  the tag in Jenkins, publishing is safe to repeat. Do not delete and recreate the tag.
- **A release was published but is bad:** `latest` is only moved by the newest release, so it has to be moved back by hand:
  ```
  docker pull eeacms/reportek-cdr:<good version>
  docker tag eeacms/reportek-cdr:<good version> eeacms/reportek-cdr:latest
  docker push eeacms/reportek-cdr:latest
  ```
  Then fix forward with a new release. The helm chart `cdr-py3` keeps the `appVersion` of the bad release until a newer one is released, change it by hand if needed.
- **Trivy fails the build:** it lists the fixable HIGH and CRITICAL vulnerabilities, update the package (the ones without a fix upstream are ignored). A finding that is
  accepted (false positive, not reachable) can be listed in a `.trivyignore` file in the root of the repository, with
  a comment saying why. If Trivy cannot run (vulnerability database download), the build is marked unstable and
  continues.
- **No email for a tag?** A failed or unstable build is always reported, a successful one is not. Check the
  tag build in Jenkins if an expected image did not show up on Docker Hub.

## Images

Built for `linux/amd64` only. Every image has the `org.opencontainers.image.revision` (commit),
`org.opencontainers.image.version` and `org.opencontainers.image.source` labels:
`docker inspect --format '{{json .Config.Labels}}' eeacms/reportek-cdr:<version>`.
