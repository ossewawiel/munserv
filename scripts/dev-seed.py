#!/usr/bin/env python3
"""Create the dev accounts that Flyway does not seed, through the real API.

Reads `other_member` and `ground_admin` from scripts/console/accounts.yaml and, on the backend
at --base-url, makes sure that:
  * each one is an active member in John's sector who can log in with the listed password
    (register, admin approves, the temporary password from the approval is changed);
  * `ground_admin` is an active ground admin (apply, admin approves);
  * one pending, unassigned verification exists in that sector, so the ground admin has
    something to answer in the mobile app.

Approval sends an e-mail, so the backend must run with the mailpit profile
(SPRING_PROFILES_ACTIVE=local,mailpit) and Mailpit must be up (infrastructure/docker).
Idempotent: a step whose result already holds is skipped, so a rerun changes nothing. When an
earlier run stopped after approval, the temporary password is read back from Mailpit.

Usage: python3 scripts/dev-seed.py [--base-url http://localhost:8080] [--mailpit-url http://localhost:8026]
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

import yaml

ACCOUNTS_FILE = Path(__file__).resolve().parent / "console" / "accounts.yaml"
SECTOR_ID = "550e8400-e29b-41d4-a716-446655440001"
SECTOR_CENTER = (-26.1367, 27.9833)
SEED_ADDRESS = "Dev seed, Northcliff"
TEMP_PASSWORD = re.compile(r"Temporary password: (\S+)", re.IGNORECASE)


class SeedError(Exception):
    pass


class Api:
    def __init__(self, base_url: str, mailpit_url: str) -> None:
        self.base = base_url.rstrip("/") + "/api/v1"
        self.mailpit = mailpit_url.rstrip("/") + "/api/v1"

    def call(self, method: str, path: str, body: dict | None = None, token: str | None = None) -> tuple[int, dict]:
        data = json.dumps(body).encode() if body is not None else None
        req = urllib.request.Request(self.base + path, data=data, method=method)
        req.add_header("Content-Type", "application/json")
        if token:
            req.add_header("Authorization", f"Bearer {token}")
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                raw = resp.read()
                return resp.status, json.loads(raw) if raw else {}
        except urllib.error.HTTPError as err:
            raw = err.read()
            try:
                return err.code, json.loads(raw) if raw else {}
            except json.JSONDecodeError:
                return err.code, {"raw": raw.decode(errors="replace")}

    def expect(self, status: int, method: str, path: str, body: dict | None = None, token: str | None = None) -> dict:
        got, payload = self.call(method, path, body, token)
        if got != status:
            raise SeedError(f"{method} {path} answered {got}, expected {status}: {payload}")
        return payload


def mailed_temp_password(api: Api, email: str) -> str | None:
    """The temporary password from the newest approval mail Mailpit holds for this address."""
    query = urllib.parse.quote(f"to:{email}")
    with urllib.request.urlopen(f"{api.mailpit}/search?query={query}", timeout=10) as resp:
        messages = json.load(resp)["messages"]
    for message in messages:
        with urllib.request.urlopen(f"{api.mailpit}/message/{message['ID']}", timeout=10) as resp:
            match = TEMP_PASSWORD.search(json.load(resp)["Text"])
        if match:
            return match.group(1)
    return None


def member_token(api: Api, email: str, password: str) -> str | None:
    status, payload = api.call("POST", "/auth/member/login", {"email": email, "password": password})
    return payload.get("accessToken") if status == 200 else None


def admin_token(api: Api, account: dict) -> str:
    payload = api.expect(200, "POST", "/auth/admin/login", {"email": account["email"], "password": account["password"]})
    return payload["tokens"]["accessToken"]


def find_pending_member_id(api: Api, admin: str, phone: str) -> str | None:
    path = f"/admin/members?sectorId={SECTOR_ID}&status=pending_approval&limit=100"
    items = api.expect(200, "GET", path, token=admin)["items"]
    return next((m["id"] for m in items if m.get("phoneNumber") == phone), None)


def ensure_member(api: Api, admin: str, account: dict) -> str:
    """Return a token for the account, creating and activating it first when needed."""
    email, password = account["email"], account["password"]
    token = member_token(api, email, password)
    if token:
        print(f"  {email}: already active")
        return token

    lat, lng = SECTOR_CENTER
    status, payload = api.call("POST", "/auth/register/web", {
        "email": email, "firstName": account["first_name"], "surname": account["surname"],
        "phone": account["phone"], "address": SEED_ADDRESS, "latitude": lat, "longitude": lng,
        "sectorId": SECTOR_ID,
    })
    if status not in (201, 409):
        raise SeedError(f"registering {email} answered {status}: {payload}")
    member_id = payload["memberId"] if status == 201 else find_pending_member_id(api, admin, account["phone"])
    if member_id is not None:
        approved = api.expect(200, "POST", f"/admin/members/{member_id}/approve", token=admin)
        match = TEMP_PASSWORD.search(approved.get("message", ""))
        temp_password = match.group(1) if match else None
    else:
        temp_password = mailed_temp_password(api, email)
    if temp_password is None:
        raise SeedError(f"{email} is active, but neither accounts.yaml nor Mailpit has a password that works")
    temp_token = member_token(api, email, temp_password)
    if not temp_token:
        raise SeedError(f"{email} cannot log in with its temporary password")
    api.expect(200, "POST", "/auth/change-password",
               {"currentPassword": temp_password, "newPassword": password}, token=temp_token)
    token = member_token(api, email, password)
    if not token:
        raise SeedError(f"{email} cannot log in after the password change")
    print(f"  {email}: registered, approved, password set")
    return token


def ensure_ground_admin(api: Api, admin: str, account: dict, token: str) -> None:
    status, info = api.call("GET", "/members/me/ground-admin", token=token)
    if status == 200 and info.get("status") == "active":
        print(f"  {account['email']}: already an active ground admin")
        return
    status, payload = api.call("POST", "/members/me/ground-admin/apply", token=token)
    if status != 200:
        raise SeedError(f"ground admin application for {account['email']} answered {status}: {payload}")
    member_id = find_member_id(api, admin, account["phone"])
    api.expect(200, "POST", f"/members/{member_id}/ground-admin/approve",
               {"applicationId": payload["applicationId"]}, token=admin)
    print(f"  {account['email']}: applied and approved as ground admin")


def find_member_id(api: Api, admin: str, phone: str) -> str:
    path = f"/admin/members?sectorId={SECTOR_ID}&limit=100"
    items = api.expect(200, "GET", path, token=admin)["items"]
    member_id = next((m["id"] for m in items if m.get("phoneNumber") == phone), None)
    if member_id is None:
        raise SeedError(f"no member with phone {phone} in sector {SECTOR_ID}")
    return member_id


def ensure_pending_verification(api: Api, admin: str, ground_admin: str) -> None:
    pending = api.expect(200, "GET", "/members/me/pending-verifications", token=ground_admin)["items"]
    if pending:
        print(f"  verification: {len(pending)} already pending for the ground admin")
        return
    issues = api.expect(200, "GET", f"/issues?sectorId={SECTOR_ID}&state=reported&limit=50", token=admin)["items"]
    answers = []
    for issue in issues:
        status, payload = api.call("POST", f"/issues/{issue['id']}/request-verification", {"type": "existence"}, token=admin)
        if status == 200:
            print(f"  verification: requested on issue {issue['id']}, unassigned")
            return
        answers.append(f"{issue['id']} -> {status} {payload.get('error', payload)}")
    raise SeedError(f"no reported issue in sector {SECTOR_ID} accepted a verification request "
                    f"(a 500 here is issue #166): {'; '.join(answers) or 'no reported issues'}")


def main() -> int:
    parser = argparse.ArgumentParser(description=(__doc__ or "").splitlines()[0])
    parser.add_argument("--base-url", default="http://localhost:8080")
    parser.add_argument("--mailpit-url", default="http://localhost:8026")
    args = parser.parse_args()

    accounts = yaml.safe_load(ACCOUNTS_FILE.read_text())
    api = Api(args.base_url, args.mailpit_url)
    try:
        admin = admin_token(api, accounts["sector_admin"])
        ensure_member(api, admin, accounts["other_member"])
        ground_admin = ensure_member(api, admin, accounts["ground_admin"])
        ensure_ground_admin(api, admin, accounts["ground_admin"], ground_admin)
        ensure_pending_verification(api, admin, ground_admin)
    except SeedError as err:
        print(f"dev-seed: {err}", file=sys.stderr)
        return 1
    except urllib.error.URLError as err:
        print(f"dev-seed: cannot reach the backend or Mailpit: {err.reason}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
