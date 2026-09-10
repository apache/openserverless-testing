<!--
  ~ Licensed to the Apache Software Foundation (ASF) under one
  ~ or more contributor license agreements.  See the NOTICE file
  ~ distributed with this work for additional information
  ~ regarding copyright ownership.  The ASF licenses this file
  ~ to you under the Apache License, Version 2.0 (the
  ~ "License"); you may not use this file except in compliance
  ~ with the License.  You may obtain a copy of the License at
  ~
  ~   http://www.apache.org/licenses/LICENSE-2.0
  ~
  ~ Unless required by applicable law or agreed to in writing,
  ~ software distributed under the License is distributed on an
  ~ "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
  ~ KIND, either express or implied.  See the License for the
  ~ specific language governing permissions and limitations
  ~ under the License.
  -->

# Optional SSO smoke test for 0.9.0

Run this test explicitly on a disposable test cluster after deploying an
OIDC-capable admin-api and the matching `ops config sso` tasks:

```sh
bash tests/11-sso-mock.sh kind
```

Use your supported test type instead of `kind` when appropriate. The defaults
match `0.9.0`: namespace `openserverless`, StatefulSet
`openserverless-system-api` and `ops setup openserverless hello`.

The test deploys a local mock OIDC provider, configures a confidential client,
performs password login, waits for the provisioned namespace and invokes the
existing hello setup. The provider validates the client and user credentials
and signs RS256 tokens with an ephemeral key. The script includes the existing
`0.9.1` retry handling for transient admin-api ingress failures.

The script creates and deletes test resources and changes the local CLI login.
It skips a cluster whose local SSO configuration is already enabled. Run it from
a dedicated test configuration and restore your normal login afterwards.

The established `tests/all.sh` suite is unchanged; the SSO test is opt-in while
its task and admin-api dependencies are being backported. Invoke the script
directly to receive its nonzero exit status on failure. The existing suite can
record `FAIL` in `_results` and still exit zero; that pre-existing behavior is
outside this backport.

Local checks without a cluster:

```sh
bash -n tests/11-sso-mock.sh
python3 -m py_compile tests/mock-oidc-provider.py
```

A cluster test is still required before promoting this backport. These syntax
checks do not validate Kubernetes deployment or the login/provisioning flow.
