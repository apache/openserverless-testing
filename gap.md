# Gap Analysis: tag-driven PR testing for `openserverless-operator` and `openserverless-task`

Note:

- this document captures the gaps identified before the current implementation branch
- the branch `feat/test-tag-hash-contract` addresses the trigger contract shift to `<test>-<hash>` and improves test log visibility
- any remaining gaps below should therefore be read as historical analysis unless they are still explicitly present after merge

## Assumption

Based on the latest clarification, the desired trigger contract is:

- `<test>-<hash>`

Where:

- `test` already encodes the target platform or runtime shape
- no extra platform or architecture field is needed
- examples of test names are `k3s` and `k3sarm`
- `hash` is the commit hash that generated the test request

The main question is therefore whether a PR in `openserverless-operator` or `openserverless-task` can propagate that tag end-to-end, trigger the right GitHub workflow, and execute the corresponding test on the intended infrastructure.

## Current state found

### Operator path

- `openserverless-testing/.github/workflows/operator-pr-test.yaml` accepts `repository_dispatch` with PR number, ref, sha, repo and selector-like data.
- `nuvolaris/openserverless-operator/.github/workflows/trigger-testing.yaml` currently enables testing from PR labels, not from a `<test>-<hash>` tag.

### Task path

- `openserverless-testing/.github/workflows/platform-ci-tests.yaml` accepts `repository_dispatch` type `olaris-testing-update` and converts the payload into a git tag.
- `openserverless-testing/.github/workflows/tests.yaml` runs the full test suite on any pushed tag matching `*-*`.
- `nuvolaris/openserverless-task` originally had no workflow producer for that dispatch.

### What was already close to the new specification

- `platform-ci-tests.yaml` already materializes a tag from two fields:
  - a logical test identifier
  - a second suffix currently named `tag`
- `tests.yaml` already treats the incoming trigger generically as `*-*`
- the historical task flow therefore was structurally closer to `<test>-<hash>` than the newer label contract based on `kind-amd` or `k3s-arm`

## Gaps

### 1. The documented trigger contract and the implemented one do not match

Evidence:

- desired contract is now `<test>-<hash>`
- current trigger implementation added in the PR flow is based on labels like `kind-amd`, `k3s-amd`, `k3s-arm`

Impact:

- the system is not yet aligned with the latest specification
- a PR tag like `k3s-abcdef1` or `k3sarm-abcdef1` is conceptually different from the currently implemented selector labels

### 2. No end-to-end PR trigger existed for `openserverless-task`

Evidence:

- `platform-ci-tests.yaml` waits for `repository_dispatch` (`olaris-testing-update`)
- `nuvolaris/openserverless-task` originally had no GitHub workflow producing it

Impact:

- a PR on `openserverless-task` could not trigger anything in `openserverless-testing`

### 3. The tag contract is only partially implemented across repos

Evidence:

- `tests.yaml` reacts generically to any tag matching `*-*`
- `platform-ci-tests.yaml` builds a tag from two payload fields, but still names the first field `platform`
- there is no canonical schema for:
  - test name
  - commit hash
  - source repository
  - PR number/ref/sha

Impact:

- the system still lacks one explicit contract shared by `operator`, `task`, and `testing`
- the current codebase does not consistently treat the trigger as `<test>-<hash>`
- some code paths are semantically aligned already, but their naming is still tied to the older abstraction

### 4. The old task tag transport loses PR identity and is not reproducible

Evidence:

- `platform-ci-tests.yaml` turns the payload into a git tag only
- that tag does not carry `pr_number`, `pr_ref`, `pr_sha`, or source repository as first-class workflow inputs
- `tests.yaml` uses static defaults for `OPS_REPO` and `OPS_BRANCH`

Impact:

- a task-triggered run cannot be pinned reliably to the exact PR commit that requested the test unless the commit identity is explicitly reconstructed from the tag
- reruns may test different code than the originally requested change

### 5. Tag parsing logic was historically built around split selectors, not `<test>-<hash>`

Evidence:

- `tests/1-deploy.sh` historically stripped a trailing suffix from the incoming tag
- many test scripts historically collapsed values at the first `-`
- this made sense for forms like `k3s-amd` or `k3s-arm`, but not for the new contract where the separator is between test name and commit hash

Impact:

- parsing must be normalized around:
  - `test`
  - `hash`
- not around:
  - platform
  - architecture
- this matters both in shell parsing and in the workflow payload field names

### 6. The current implementation still assumes architecture-encoded test names in deploy logic

Evidence:

- deploy/test support in `tests/1-deploy.sh` is centered on names like `kind`, `k3s-amd`, `k3s-arm`, `k8s`
- the new examples provided are `k3s` and `k3sarm`

Impact:

- there is a naming mismatch between the latest desired contract and the currently supported deploy/test names
- either:
  - test names must be normalized to the new canonical names
  - or the specification must explicitly preserve the current names

Clarification:

- under the latest requirement, the platform distinction is not a second dimension
- it is already encoded in the test name itself

### 7. Platform support is incomplete in the actual deploy path

Evidence:

- active deploy support in `tests/1-deploy.sh` is limited
- several other targets remain commented out

Impact:

- even with a correct `<test>-<hash>` contract, only a subset of tests can currently execute end-to-end

### 8. Operator PR execution originally was not pinned to the requested SHA

Evidence:

- the earlier operator PR flow cloned the PR branch without checking out the requested `PR_SHA`

Impact:

- if the branch moved after dispatch, the workflow could test code different from the commit that requested the run

Note:

- this was one of the concrete problems identified during implementation and has already been addressed in the new workflow changes

### 9. There was no equivalent "materialize PR code locally" step for `openserverless-task`

Evidence:

- operator flow had dedicated PR checkout logic
- generic task tag flow did not clone `openserverless-task` at the requested PR revision

Impact:

- task PRs could not be tested against their actual contents in a deterministic way

### 10. Validation and guardrails are still tied to the wrong abstraction

Evidence:

- the recent implementation validates selector-like values
- the latest specification says the trigger should be `<test>-<hash>`

Impact:

- validation should move to:
  - allowed test names
  - valid commit-hash format
- instead of validating synthetic platform-architecture pairs

### 11. Workflow and payload naming still use legacy terms

Evidence:

- `platform-ci-tests.yaml` still refers to `client_payload.platform`
- several documents and scripts still speak about selector or platform-architecture values

Impact:

- even where behavior is compatible with `<test>-<hash>`, the naming remains misleading
- future maintenance will be error-prone until the terminology becomes:
  - `test`
  - `hash`
  - source repo / PR metadata

## What in the previous analysis was still useful

These earlier findings remain relevant even after the specification change:

1. the system needed a real PR trigger for `openserverless-task`
2. the task tag flow was losing PR identity
3. parsing was inconsistent and needed normalization
4. deploy support was only partial
5. deterministic checkout by SHA was missing in some paths
6. workflow naming was obscuring the real trigger contract

## Minimum missing pieces under the new specification

1. A single trigger contract shared by `operator`, `task`, and `testing`:
   - repo
   - pr number
   - ref
   - sha
   - tag `<test>-<hash>`
2. A clear canonical list of test names:
   - for example `k3s`, `k3sarm`, `kind`
3. Parsing logic that extracts:
   - test name
   - commit hash
4. A task-specific workflow in `openserverless-testing` that checks out the requested task PR revision, not just a tag
5. Deterministic checkout by SHA for both operator and task flows
6. A mapping layer in `openserverless-testing` from canonical test name to the actual infrastructure setup used by the tests
7. Terminology cleanup so workflows, payloads and docs consistently say:
   - `test`
   - `hash`
   - not `platform`
   - not `architecture`
