#!/usr/bin/env python3
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

import base64
import json
import os
import time
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs

from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import padding, rsa


PRIVATE_KEY = rsa.generate_private_key(public_exponent=65537, key_size=2048)
KID = "openserverless-sso-mock"


def b64url(value):
    return base64.urlsafe_b64encode(value).decode("ascii").rstrip("=")


def b64url_int(value):
    length = (value.bit_length() + 7) // 8
    return b64url(value.to_bytes(length, byteorder="big"))


def write_json(handler, status, payload):
    body = json.dumps(payload).encode("utf-8")
    handler.send_response(status)
    handler.send_header("Content-Type", "application/json")
    handler.send_header("Content-Length", str(len(body)))
    handler.end_headers()
    handler.wfile.write(body)


def public_jwk():
    numbers = PRIVATE_KEY.public_key().public_numbers()
    return {
        "kty": "RSA",
        "kid": KID,
        "use": "sig",
        "alg": "RS256",
        "n": b64url_int(numbers.n),
        "e": b64url_int(numbers.e),
    }


def sign_token():
    now = int(time.time())
    issuer = os.environ["MOCK_OIDC_ISSUER"]
    client_id = os.environ["MOCK_OIDC_CLIENT_ID"]
    username = os.environ["MOCK_OIDC_USERNAME"]
    group = os.environ["MOCK_OIDC_GROUP"]
    payload = {
        "iss": issuer,
        "sub": f"mock-sub-{username}",
        "aud": client_id,
        "iat": now,
        "nbf": now - 5,
        "exp": now + 600,
        "preferred_username": username,
        "email": os.environ.get("MOCK_OIDC_EMAIL", f"{username}@example.test"),
        "groups": [group],
    }
    header = {"alg": "RS256", "typ": "JWT", "kid": KID}
    encoded_header = b64url(json.dumps(header, separators=(",", ":")).encode("utf-8"))
    encoded_payload = b64url(json.dumps(payload, separators=(",", ":")).encode("utf-8"))
    signing_input = f"{encoded_header}.{encoded_payload}".encode("ascii")
    signature = PRIVATE_KEY.sign(signing_input, padding.PKCS1v15(), hashes.SHA256())
    return f"{encoded_header}.{encoded_payload}.{b64url(signature)}"


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        print(fmt % args, flush=True)

    def do_GET(self):
        issuer = os.environ["MOCK_OIDC_ISSUER"]
        if self.path == "/healthz":
            write_json(self, 200, {"status": "ok"})
            return
        if self.path == "/realms/mock/.well-known/openid-configuration":
            write_json(
                self,
                200,
                {
                    "issuer": issuer,
                    "token_endpoint": f"{issuer}/protocol/openid-connect/token",
                    "jwks_uri": f"{issuer}/protocol/openid-connect/certs",
                },
            )
            return
        if self.path == "/realms/mock/protocol/openid-connect/certs":
            write_json(self, 200, {"keys": [public_jwk()]})
            return
        write_json(self, 404, {"error": "not_found"})

    def do_POST(self):
        if self.path != "/realms/mock/protocol/openid-connect/token":
            write_json(self, 404, {"error": "not_found"})
            return

        length = int(self.headers.get("Content-Length", "0"))
        form = parse_qs(self.rfile.read(length).decode("utf-8"))
        client_id = form.get("client_id", [""])[0]
        username = form.get("username", [""])[0]
        password = form.get("password", [""])[0]
        grant_type = form.get("grant_type", [""])[0]

        if not self._valid_client_auth(client_id):
            write_json(self, 401, {"error": "invalid_client"})
            return
        if grant_type != "password":
            write_json(self, 400, {"error": "unsupported_grant_type"})
            return
        if username != os.environ["MOCK_OIDC_USERNAME"] or password != os.environ["MOCK_OIDC_PASSWORD"]:
            write_json(self, 400, {"error": "invalid_grant"})
            return

        write_json(
            self,
            200,
            {
                "access_token": sign_token(),
                "token_type": "Bearer",
                "expires_in": 600,
            },
        )

    def _valid_client_auth(self, form_client_id):
        expected_id = os.environ["MOCK_OIDC_CLIENT_ID"]
        expected_secret = os.environ["MOCK_OIDC_CLIENT_SECRET"]
        authorization = self.headers.get("Authorization", "")
        if authorization.startswith("Basic "):
            raw = base64.b64decode(authorization.split(" ", 1)[1]).decode("utf-8")
            client_id, client_secret = raw.split(":", 1)
            return client_id == expected_id and client_secret == expected_secret
        return form_client_id == expected_id and not expected_secret


if __name__ == "__main__":
    HTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
