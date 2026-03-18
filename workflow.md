# Workflow Notes

Note:

- this document describes both the historical state and the target contract
- the branch `feat/test-tag-hash-contract` implements the `<test>-<hash>` trigger flow and clearer step-by-step test logging
- references below to the earlier selector-style contract are kept only to explain the transition

## Repositories involved

- `nuvolaris/openserverless-operator`
- `nuvolaris/openserverless-task`
- `nuvolaris/openserverless-testing`

## Latest desired contract

The latest specification says the trigger should be:

- `<test>-<hash>`

Where:

- `test` already includes the platform distinction
- no extra platform or architecture field is needed
- examples given are:
  - `k3s`
  - `k3sarm`
- `hash` is the commit hash that generated the test

This is different from the earlier interpretation based on selectors like `k3s-amd` or `kind-amd`.

The key clarification is:

- platform is already part of the test name
- there is no independent platform or architecture dimension to reconstruct later

## Important GitHub Actions behavior

### Why branch-only changes are not enough for end-to-end PR testing

For PR-triggered flows:

- source repos use `pull_request_target`
- `pull_request_target` reads the workflow from the base branch of the PR
- `repository_dispatch` workflows in `openserverless-testing` must also exist on the branch GitHub uses for the target repo

Practical consequence:

- opening a PR against `main` does not automatically use workflow logic that exists only in the PR branch
- the new behavior becomes real only after the relevant workflow changes are available on `main`

## What was implemented during this work

### Source repo triggers

Feature branches added PR-trigger logic in:

- `openserverless-operator/.github/workflows/trigger-testing.yaml`
- `openserverless-task/.github/workflows/trigger-testing.yaml`

Those changes currently enable testing from PR labels and dispatch to `openserverless-testing`.
That behavior was enough to validate the PR-trigger pipeline, but its naming contract is still older than the final requirement.

### Testing repo flows

Feature branches added or updated:

- `openserverless-testing/.github/workflows/operator-pr-test.yaml`
- `openserverless-testing/.github/workflows/task-pr-test.yaml`
- `openserverless-testing/.github/workflows/tests.yaml`

Main improvements introduced:

- deterministic checkout by `PR_SHA`
- dedicated task PR workflow
- common test sequence extraction
- more consistent selector parsing than before
- explicit `OPS_BRANCH=main` in the shared GitHub test path

## Important note: current implementation vs latest specification

The implemented PR-trigger flow was built around label values like:

- `kind-amd`
- `k3s-amd`
- `k3s-arm`

The latest specification instead says the tag should be:

- `<test>-<hash>`

Examples:

- `k3s-<hash>`
- `k3sarm-<hash>`

So the code currently merged on `main` improved the trigger pipeline, but it is not yet fully aligned with this final naming contract.

One important nuance:

- the older tag-driven task path in `platform-ci-tests.yaml` is structurally closer to `<test>-<hash>`
- the newer selector-based PR trigger improved orchestration and PR metadata handling, but uses the wrong external naming contract

## Historical testing flow

### Operator

Previous operator path:

1. `openserverless-operator/.github/workflows/trigger-testing.yaml`
2. trigger originally came from:
   - issue comment `/testing <platform>`
   - manual `workflow_dispatch`
3. workflow dispatched `repository_dispatch` to `openserverless-testing`
4. `openserverless-testing/.github/workflows/operator-pr-test.yaml` built a temporary operator image and ran tests

### Task

Previous task path:

1. `openserverless-testing/.github/workflows/platform-ci-tests.yaml` accepted `repository_dispatch`
2. payload was converted into a git tag
3. `openserverless-testing/.github/workflows/tests.yaml` ran tests on tag push

Original missing piece:

- `openserverless-task` did not have a workflow producer for that dispatch

What was already aligned in spirit:

- `platform-ci-tests.yaml` already creates a tag from two parts
- `tests.yaml` already accepts any tag matching `*-*`
- this means the historical task path was already closer to a canonical `<test>-<hash>` trigger than the later `kind-amd` style label naming

## Current code paths that are still useful under the new contract

Even with the new `<test>-<hash>` specification, these pieces remain useful:

- `openserverless-testing/.github/workflows/operator-pr-test.yaml`
  Purpose:
  checkout operator PR by SHA, build temporary image, run tests
- `openserverless-testing/.github/workflows/task-pr-test.yaml`
  Purpose:
  checkout task PR by SHA and run tests from the requested PR contents
- `openserverless-testing/.github/workflows/tests.yaml`
  Purpose:
  generic tag-based test entry point for `*-*`
- `openserverless-testing/tests/run-gh-suite.sh`
  Purpose:
  central GitHub test sequence

## What needs realignment for the latest specification

### 1. Trigger naming

The system must treat the tag as:

- `<test>-<hash>`

Not as:

- `<platform>-<architecture>`

### 2. Canonical test names

The system needs one stable list of accepted test names.

Examples currently mentioned by the latest clarification:

- `k3s`
- `k3sarm`

That means the code should not rely on split forms like:

- `k3s-amd`
- `k3s-arm`

unless those remain officially supported aliases.

### 3. Parser behavior

Parsing should extract:

- `test`
- `hash`

The earlier selector parser was built for names that embedded an extra `-amd` or `-arm` part.

### 4. Mapping from test name to infrastructure

Because platform is already encoded in the test name, the test runner should map:

- `k3s` -> the corresponding infrastructure path
- `k3sarm` -> the corresponding infrastructure path

instead of reconstructing platform and architecture as separate dimensions.

### 5. Workflow payload naming

Even where behavior is already close, workflow fields should stop implying a separate platform dimension.

Examples of terminology that should be renamed in the next code alignment:

- `platform` -> `test`
- selector -> tag or test selector only if it really means `<test>-<hash>`

## Current deploy/test support in `openserverless-testing`

Current deploy logic is still based on names such as:

- `kind`
- `k3s-amd`
- `k3s-arm`
- `k8s`

This is one of the main remaining mismatches with the latest desired naming.

The current deploy logic therefore supports the infrastructure execution, but not yet the final canonical naming expected by the new contract.

## Operator image build and publication

### Temporary image used for PR testing

File:

- `openserverless-testing/.github/workflows/operator-pr-test.yaml`

What happens:

1. testing workflow clones the operator PR
2. checks out the requested `PR_SHA`
3. builds an image from the PR source
4. pushes it to GHCR as a temporary test image
5. patches the task configuration to use that image during tests

Destination:

- `ghcr.io/<repository_owner>/openserverless-testing:pr-<PR_NUMBER>-<SHORT_SHA>`

This is only the test image.

### Official operator image publication

Files:

- `openserverless-operator/.github/workflows/image.yml`
- `openserverless-operator/TaskfileBuild.yml`
- `openserverless-operator/Dockerfile`

Trigger:

- `push.tags: [0-9]*`

Important conclusion:

- there is no automatic path today from “PR tests passed” to “publish official operator image”
- official publication still depends on pushing a release tag

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

Current tag creation remains manual or task-driven:

- `openserverless-operator/Taskfile.yml` task `tag`
- `openserverless-operator/Taskfile.yml` task `tag-commit-push`

So the current release path is:

1. someone creates or pushes a numeric version tag
2. tag push triggers `image.yml`
3. `image.yml` builds and publishes the official image

## Validation performed during implementation

Static checks executed during the implementation work:

- `bash -n` on updated shell scripts in `openserverless-testing`
- YAML parsing with Ruby for modified workflows in all three repositories
- a real trigger validation using:
  - an operator PR
  - label `kind-amd`
  - successful dispatch into `openserverless-testing`

That real validation confirmed:

- the PR-trigger pipeline works
- `repository_dispatch` reaches `openserverless-testing`
- the operator PR test workflow starts correctly

But it validated the selector-style contract, not yet the final `<test>-<hash>` contract.

## Open points

### 1. Exact meaning of “tag”

The latest requirement uses the word “tag” as:

- `<test>-<hash>`

This should now become the canonical name everywhere in code and docs.

### 2. Transition plan

There are now two conceptual layers:

- trigger pipeline improvements already implemented and merged
- final naming contract `<test>-<hash>` still to be aligned

### 3. Next update needed in code

To fully align the codebase, the next round should update:

- trigger parsing
- validation rules
- test-name allowlists
- deploy mapping
- workflow payload field names
- documentation

so everything consistently speaks in terms of:

- `test`
- `hash`

and no longer in terms of:

- platform
- architecture
