# Gap Analysis: PR-driven testing for `openserverless-operator` and `openserverless-task`

## Assumption

Based on the clarification, the trigger contract is a selector shaped as:

- `<platform>-<architecture>`

Example: `k3s-amd`, `k3s-arm`.

The main question is therefore whether a PR in `openserverless-operator` or `openserverless-task` can propagate that selector end-to-end, trigger the right GitHub workflow, and execute on the matching infrastructure.

## Current state found

### Operator path

- `openserverless-testing/.github/workflows/operator-pr-test.yaml:21-135` already accepts `repository_dispatch` with PR number, ref, sha, repo and platform.
- `nuvolaris/openserverless-operator/.github/workflows/trigger-testing.yaml:21-90` can dispatch that event, but only from:
  - an issue comment `/testing <platform>`
  - a manual `workflow_dispatch`

### Task path

- `openserverless-testing/.github/workflows/platform-ci-tests.yaml:22-40` accepts `repository_dispatch` type `olaris-testing-update` and converts the payload into a git tag.
- `openserverless-testing/.github/workflows/tests.yaml:21-97` runs the full test suite on any pushed tag matching `*-*`.
- `nuvolaris/openserverless-task` currently has no `.github/workflows` directory, so there is no producer for that dispatch.

## Gaps

### 1. No end-to-end PR trigger exists for `openserverless-task`

Evidence:

- `platform-ci-tests.yaml` waits for `repository_dispatch` (`olaris-testing-update`), but `nuvolaris/openserverless-task` has no GitHub workflows at all.

Impact:

- A PR on `openserverless-task` cannot currently trigger anything in this repository.

### 2. Operator flow is not tag-driven today

Evidence:

- `nuvolaris/openserverless-operator/.github/workflows/trigger-testing.yaml:21-57` only parses:
  - `workflow_dispatch` inputs
  - issue comments starting with `/testing `

Impact:

- The current operator flow still requires a comment or manual dispatch instead of a tag-shaped selector propagated automatically from the PR flow.

### 3. The selector contract is only partially implemented across repos

Evidence:

- `operator` dispatch passes a single `platform` field, whose value is expected to already contain the combined selector such as `k3s-amd`.
- `platform-ci-tests.yaml:27` builds a tag as `<platform>-<tag>`, but the second field is still generically named `tag`, not `architecture`.
- `tests.yaml:21-24` reacts to any tag matching `*-*`.

Impact:

- The system has no canonical representation for:
  - which repo is under test
  - which platform/infrastructure should be targeted
  - which architecture is being targeted
  - which PR commit should be tested

### 4. There is no task-specific PR workflow in `openserverless-testing`

Evidence:

- The operator has a dedicated entry point: `operator-pr-test.yaml:21-135`.
- The task path only has the generic tag flow: `platform-ci-tests.yaml` -> `tests.yaml`.

Impact:

- `openserverless-task` does not have a PR-aware execution path comparable to the operator one.
- The generic tag flow cannot attach PR metadata to the run in the same way.

### 5. The tag-based transport loses PR identity and is not reproducible

Evidence:

- `platform-ci-tests.yaml:27-40` turns the payload into a git tag only.
- That tag stores no `pr_number`, `pr_ref`, `pr_sha`, or source repository.
- `tests.yaml:27-29` uses static defaults for `OPS_REPO` and `OPS_BRANCH`.

Impact:

- A task-triggered run cannot be pinned to the exact PR commit that requested the test.
- Two runs with the same `<platform>-<tag>` collide.
- A rerun may test different code than the one originally requested.

### 6. Selector parsing is inconsistent with the `<platform>-<architecture>` contract

Evidence:

- `tests/1-deploy.sh:18-22` keeps selectors like `k3s-amd` and `k3s-arm`, but only strips a trailing numeric suffix.
- Many later scripts collapse the selector to the first `-` segment, for example:
  - `tests/6-login.sh:18-19`
  - `tests/7-static.sh:18-19`
  - `tests/8-user-redis.sh:18-19`
  - same pattern also appears in `tests/9a-user-ferretdb.sh`, `tests/9b-user-postgres.sh`, `tests/10-user-minio.sh`, `tests/14-runtime-testing.sh`

Impact:

- The selector is not preserved consistently end-to-end.
- `k3s-amd` and `k3s-arm` are distinguished in deploy, but become just `k3s` in many subsequent test steps.

### 7. Platform support is incomplete in the actual deploy path

Evidence:

- `tests/1-deploy.sh:45-79` actively supports only `kind`, `k3s-amd`, `k3s-arm`.
- `tests/1-deploy.sh:86-212` has `mk8s`, `eks`, `aks`, `gke`, `osh` commented out.
- `tests/1-deploy.sh:214-229` supports generic `k8s`.
- `tests/all.sh:29-37` still advertises more platforms than `1-deploy.sh` actually enables.

Impact:

- "Selected infrastructure" is only partially true today.
- Any tag/label selecting `mk8s`, `eks`, `aks`, `gke`, or `osh` will not reach a working deploy path in the current GitHub workflow.

### 8. Operator PR execution is not pinned to the requested SHA

Evidence:

- `operator-pr-test.yaml:45-49` clones `--branch "$PR_REF"` but does not checkout `PR_SHA`.
- `PR_SHA` is only used for the image tag at `operator-pr-test.yaml:69-75`.

Impact:

- If the PR branch moves after dispatch, the workflow may build and test a newer commit than the one that triggered the run.

### 9. There is no equivalent "materialize PR code locally" step for `openserverless-task`

Evidence:

- Operator flow clones the PR repo and patches `_operator/olaris/opsroot.json`, then exports `OPS_ROOT` (`operator-pr-test.yaml:45-87`).
- The generic tag flow in `tests.yaml` does not clone `openserverless-task`, does not checkout a PR ref/sha, and does not set `OPS_ROOT`.

Impact:

- Even after adding a PR trigger in `openserverless-task`, this repo still lacks the execution path required to test the actual PR contents instead of a default branch.

### 10. Validation and guardrails are missing

Evidence:

- `platform-ci-tests.yaml:27-40` accepts raw `platform` and `tag` strings and pushes them directly as git tags.
- `operator-pr-test.yaml:26-30` accepts raw payload fields and passes `platform` directly into the test scripts.

Impact:

- Unsupported `<platform>-<architecture>` combinations fail late, inside the test workflow.
- There is no central allowlist for valid repositories or selectors.

## Minimum missing pieces before the target flow can work

1. A single trigger contract shared by `operator`, `task`, and `testing`:
   - repo
   - pr number
   - ref
   - sha
   - selector `<platform>-<architecture>`
2. A PR-trigger workflow in `nuvolaris/openserverless-task`.
3. A task-specific workflow in `openserverless-testing` that checks out the requested task PR revision, not just a tag.
4. Deterministic checkout by SHA for both operator and task flows.
5. A routing layer in `openserverless-testing` that maps `<platform>-<architecture>` to supported infrastructures.
6. A normalized parser for selectors, instead of the current mixed comment/tag/string conventions.
