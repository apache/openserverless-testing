# Workflow Notes

## Repositories involved

- `nuvolaris/openserverless-operator`
- `nuvolaris/openserverless-task`
- `nuvolaris/openserverless-testing`

## Goal

Enable a PR in `openserverless-operator` or `openserverless-task` to trigger the corresponding test workflow in `openserverless-testing`, using a PR label/tag shaped as:

- `<platform>-<architecture>`

Examples:

- `k3s-amd`
- `k3s-arm`
- `kind-amd`

## Current repositories and branches used during this analysis

Implementation work was pushed to:

- `feat/pr-tag-platform-arch-testing` in `openserverless-testing`
- `feat/pr-tag-platform-arch-testing` in `openserverless-operator`
- `feat/pr-tag-platform-arch-testing` in `openserverless-task`

## Important GitHub Actions behavior

### Why branch-only changes are not enough for end-to-end PR testing

For the new PR-trigger flow:

- source repos use `pull_request_target`
- `pull_request_target` reads the workflow from the base branch of the PR
- `repository_dispatch` workflows in `openserverless-testing` must also exist on the target branch used by GitHub

Practical consequence:

- opening a PR on `openserverless-operator` against `main` does not automatically use the new trigger logic if that logic only exists in the PR branch
- the new flow becomes real only after the relevant workflow changes are available on the base branch, typically `main`

Minimum merge set for real usage:

1. merge `openserverless-testing`
2. merge `openserverless-operator`
3. merge `openserverless-task` if task PRs must also trigger tests

## Current testing flow before the new changes

### Operator

Existing trigger path:

1. `openserverless-operator/.github/workflows/trigger-testing.yaml`
2. trigger came from:
   - issue comment `/testing <platform>`
   - manual `workflow_dispatch`
3. workflow collected:
   - PR number
   - PR ref
   - PR sha
   - source repo
   - platform selector
4. workflow dispatched `repository_dispatch` to `openserverless-testing`
5. `openserverless-testing/.github/workflows/operator-pr-test.yaml` built a temporary operator image and executed tests

### Task

Existing trigger path:

1. `openserverless-testing/.github/workflows/platform-ci-tests.yaml` could receive `repository_dispatch`
2. it converted payload into a git tag
3. `openserverless-testing/.github/workflows/tests.yaml` ran tests on tag push

Missing piece:

- `openserverless-task` had no `.github/workflows` directory, so there was no workflow producing that dispatch from a PR

## New testing flow implemented in the feature branches

### Source of truth for enabling tests

A PR label/tag matching one of these selectors enables the process:

- `kind-amd`
- `kind-arm`
- `k3s-amd`
- `k3s-arm`
- `k8s-amd`
- `k8s-arm`
- `mk8s-amd`
- `mk8s-arm`
- `eks-amd`
- `eks-arm`
- `aks-amd`
- `aks-arm`
- `gke-amd`
- `gke-arm`
- `osh-amd`
- `osh-arm`

### Operator flow after the feature changes

Files:

- `openserverless-operator/.github/workflows/trigger-testing.yaml`
- `openserverless-testing/.github/workflows/operator-pr-test.yaml`

Flow:

1. PR in `openserverless-operator` receives a valid label
2. `pull_request_target` runs on:
   - `labeled`
   - `synchronize`
   - `reopened`
3. workflow scans PR labels and picks the first valid `<platform>-<architecture>` selector
4. workflow fetches PR details via `gh api`
5. workflow dispatches `operator-pr-test` to `openserverless-testing`
6. testing workflow clones the operator PR branch
7. testing workflow explicitly checks out the requested `PR_SHA`
8. testing workflow builds a temporary operator image
9. testing workflow patches `opsroot.json`
10. testing workflow runs the test suite on the selected infrastructure

### Task flow after the feature changes

Files:

- `openserverless-task/.github/workflows/trigger-testing.yaml`
- `openserverless-testing/.github/workflows/task-pr-test.yaml`

Flow:

1. PR in `openserverless-task` receives a valid label
2. `pull_request_target` runs on:
   - `labeled`
   - `synchronize`
   - `reopened`
3. workflow scans PR labels and picks the first valid selector
4. workflow fetches PR details via `gh api`
5. workflow dispatches `task-pr-test` to `openserverless-testing`
6. testing workflow clones the task PR branch
7. testing workflow explicitly checks out the requested `PR_SHA`
8. testing workflow sets `OPS_ROOT` to the checked out task tree
9. testing workflow runs the test suite on the selected infrastructure

## Changes made in `openserverless-testing`

### New workflows

- `./.github/workflows/task-pr-test.yaml`

Purpose:

- dedicated repository-dispatch workflow for PR testing of `openserverless-task`

### Updated workflows

- `./.github/workflows/operator-pr-test.yaml`
- `./.github/workflows/tests.yaml`

Main updates:

- operator PR testing now checks out the exact requested SHA
- common test execution is centralized through `tests/run-gh-suite.sh`
- selector is passed consistently as one input to the suite

### New selector normalization

Files:

- `./tests/lib/selector.sh`
- `./tests/run-gh-suite.sh`

Purpose:

- normalize `<platform>-<architecture>` once
- preserve distinctions like `k3s-amd` vs `k3s-arm`
- remove inconsistent parsing scattered across test scripts

### Test scripts updated to use shared selector parsing

Updated:

- `./tests/1-deploy.sh`
- `./tests/2-ssl.sh`
- `./tests/6-login.sh`
- `./tests/7-static.sh`
- `./tests/8-user-redis.sh`
- `./tests/9a-user-ferretdb.sh`
- `./tests/9b-user-postgres.sh`
- `./tests/10-user-minio.sh`
- `./tests/12-nuv-mac.sh`
- `./tests/14-runtime-testing.sh`
- `./tests/all.sh`

Why this mattered:

- before the change, many scripts reduced `k3s-amd` and `k3s-arm` to `k3s`
- deploy logic distinguished them, but later test steps did not preserve the selector consistently

## Current deploy/test platform support in `openserverless-testing`

Effective support in `tests/1-deploy.sh`:

- `kind`
- `k3s-amd`
- `k3s-arm`
- `k8s`

Present but commented out in deploy path:

- `mk8s`
- `eks`
- `aks`
- `gke`
- `osh`

This means the label set is broader than the currently active deploy implementation. Some selectors are accepted by workflow validation, but their deploy path still depends on commented or incomplete code in `tests/1-deploy.sh`.

## Operator image build and publication

### Temporary image used for PR testing

File:

- `openserverless-testing/.github/workflows/operator-pr-test.yaml`

What happens:

1. testing workflow clones the operator PR
2. builds an image from the PR source
3. pushes it to GHCR as a temporary test image
4. patches the task configuration to use that image during tests

Destination:

- `ghcr.io/<repository_owner>/openserverless-testing:pr-<PR_NUMBER>-<SHORT_SHA>`

This is a testing image, not the official published operator image.

### Official operator image publication

Files:

- `openserverless-operator/.github/workflows/image.yml`
- `openserverless-operator/TaskfileBuild.yml`
- `openserverless-operator/Dockerfile`

Trigger:

- `push.tags: [0-9]*`

Important conclusion:

- there is currently no automatic path from “PR tests passed” to “publish official operator image”
- publication depends on a tag push

### Where the official operator image is published

Registry login in workflow:

- `vars.IMAGE_REGISTRY || 'registry.hub.docker.com'`

Image name:

- `MY_OPERATOR_IMAGE` if set
- otherwise default from `Dockerfile`

Dockerfile default:

- `registry.hub.docker.com/apache/openserverless-operator`

Actual push implementation:

- `task buildx-and-push`
- which runs `docker buildx build ... --push`

### How the publish tag is created today

There is no workflow that automatically creates the release tag after tests or after merge.

Current tag creation is manual or task-driven:

- `openserverless-operator/Taskfile.yml` task `tag`
- `openserverless-operator/Taskfile.yml` task `tag-commit-push`

So the current release path is:

1. someone creates or pushes a numeric version tag
2. tag push triggers `image.yml`
3. `image.yml` runs tests/build and then publishes the official image

## Validation performed during implementation

Static checks executed:

- `bash -n` on updated shell scripts in `openserverless-testing`
- YAML parsing with Ruby for modified workflows in all three repositories
- quick selector parsing checks for:
  - `kind-amd`
  - `k3s-arm`
  - `k8s-arm`

Not executed:

- full end-to-end GitHub Actions run on live PRs
- real registry publication test for the final operator release image

## Open points

### 1. Label naming

The implementation assumes GitHub PR labels are the “tag” mentioned in the process description.

### 2. Multiple valid labels on the same PR

Current logic picks the first matching valid selector found on the PR.

### 3. Release automation

If desired, a future improvement could connect:

- PR test success
- merge to `main`
- release tag creation
- official image publication

Today these are still separate processes.
