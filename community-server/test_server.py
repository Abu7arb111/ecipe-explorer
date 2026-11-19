#!/usr/bin/env python3
"""End-to-end tests for server.py. Run with:  python3 test_server.py

Starts the real HTTP server on a free port and talks to it the way the app does,
with JSON shaped exactly like Swift's JSONEncoder output for `Recipe`.
"""

import json
import os
import tempfile
import threading
import unittest
import urllib.error
import urllib.request
import uuid
from http.server import ThreadingHTTPServer

import server


def make_recipe(title="Weeknight Curry", author_id=None):
    recipe = {
        "id": str(uuid.uuid4()).upper(),
        "title": title,
        "description": "Quick and cozy.",
        "category": "Dinner",
        "cuisine": "Indian",
        "prepTime": 10,
        "cookTime": 25,
        "servings": 4,
        "difficulty": "Easy",
        "rating": 0,
        "author": "Chef Ahmad",
        "imageURL": "",
        "tags": ["Vegetarian"],
        "ingredients": [{"id": str(uuid.uuid4()).upper(), "item": "Chickpeas", "amount": "1 can"}],
        "instructions": ["Simmer everything.", "Serve with rice."],
        "isUserCreated": True,
        "likes": 7,          # personal data the server must strip
        "dislikes": 2,
        "userRating": 5,
        "userReaction": "like",
    }
    if author_id:
        recipe["authorID"] = author_id
    return recipe


class User:
    def __init__(self):
        self.id = str(uuid.uuid4()).upper()
        self.token = str(uuid.uuid4()).upper() + str(uuid.uuid4()).upper()

    def headers(self):
        return {"X-Author-ID": self.id, "X-Author-Token": self.token}


class ServerTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.data_path = os.path.join(self.tmp.name, "feed.json")
        self._start()
        self.alice, self.bob = User(), User()

    def tearDown(self):
        self._stop()
        self.tmp.cleanup()

    def _start(self):
        server.Handler.store = server.CommunityStore(self.data_path)
        server.Handler.log_message = lambda *args: None  # keep test output quiet
        self.httpd = ThreadingHTTPServer(("127.0.0.1", 0), server.Handler)
        self.base = f"http://127.0.0.1:{self.httpd.server_address[1]}"
        self.thread = threading.Thread(target=self.httpd.serve_forever, daemon=True)
        self.thread.start()

    def _stop(self):
        self.httpd.shutdown()
        self.httpd.server_close()

    def call(self, method, path, body=None, user=None, headers=None):
        data = json.dumps(body).encode() if body is not None else None
        request = urllib.request.Request(self.base + path, data=data, method=method)
        if data is not None:
            request.add_header("Content-Type", "application/json")
        for key, value in ((user.headers() if user else {}) | (headers or {})).items():
            request.add_header(key, value)
        try:
            with urllib.request.urlopen(request) as response:
                raw = response.read()
                return response.status, (json.loads(raw) if raw else None)
        except urllib.error.HTTPError as error:
            raw = error.read()
            return error.code, (json.loads(raw) if raw else None)

    # Ideal conditions ----------------------------------------------------

    def test_published_recipe_is_visible_to_everyone(self):
        status, published = self.call("POST", "/recipes", make_recipe(), self.alice)
        self.assertEqual(status, 201)
        self.assertEqual(published["authorID"], self.alice.id)
        self.assertRegex(published["publishedAt"], r"^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ$")

        status, feed = self.call("GET", "/recipes")  # no credentials needed to browse
        self.assertEqual(status, 200)
        self.assertEqual([r["id"] for r in feed], [published["id"]])

    def test_personal_data_is_stripped_on_publish(self):
        _, published = self.call("POST", "/recipes", make_recipe(), self.alice)
        self.assertEqual((published["likes"], published["dislikes"]), (0, 0))
        self.assertNotIn("userRating", published)
        self.assertNotIn("userReaction", published)

    def test_author_can_edit_and_publish_date_is_kept(self):
        recipe = make_recipe()
        _, published = self.call("POST", "/recipes", recipe, self.alice)
        recipe["title"] = "Even Better Curry"
        recipe["publishedAt"] = "1999-01-01T00:00:00Z"  # client can't rewrite history
        status, updated = self.call("PUT", f"/recipes/{recipe['id']}", recipe, self.alice)
        self.assertEqual(status, 200)
        self.assertEqual(updated["title"], "Even Better Curry")
        self.assertEqual(updated["publishedAt"], published["publishedAt"])

    def test_author_can_delete(self):
        recipe = make_recipe()
        self.call("POST", "/recipes", recipe, self.alice)
        status, _ = self.call("DELETE", f"/recipes/{recipe['id']}", user=self.alice)
        self.assertEqual(status, 204)
        self.assertEqual(self.call("GET", "/recipes")[1], [])

    def test_lowercase_ids_are_accepted(self):
        recipe = make_recipe()
        self.call("POST", "/recipes", recipe, self.alice)
        status, _ = self.call("GET", f"/recipes/{recipe['id'].lower()}")
        self.assertEqual(status, 200)

    def test_data_survives_restart(self):
        recipe = make_recipe()
        self.call("POST", "/recipes", recipe, self.alice)
        self._stop()
        self._start()
        self.assertEqual(len(self.call("GET", "/recipes")[1]), 1)
        # Ownership survives too: Bob still can't edit after the restart.
        self.assertEqual(self.call("PUT", f"/recipes/{recipe['id']}", recipe, self.bob)[0], 403)

    # Ownership -----------------------------------------------------------

    def test_other_user_cannot_edit(self):
        recipe = make_recipe()
        self.call("POST", "/recipes", recipe, self.alice)
        recipe["title"] = "Hacked"
        status, body = self.call("PUT", f"/recipes/{recipe['id']}", recipe, self.bob)
        self.assertEqual(status, 403)
        self.assertIn("error", body)
        self.assertEqual(self.call("GET", f"/recipes/{recipe['id']}")[1]["title"], "Weeknight Curry")

    def test_other_user_cannot_delete(self):
        recipe = make_recipe()
        self.call("POST", "/recipes", recipe, self.alice)
        self.assertEqual(self.call("DELETE", f"/recipes/{recipe['id']}", user=self.bob)[0], 403)
        self.assertEqual(len(self.call("GET", "/recipes")[1]), 1)

    def test_forged_author_id_with_wrong_token_is_rejected(self):
        recipe = make_recipe()
        self.call("POST", "/recipes", recipe, self.alice)
        forger = User()
        forger.id = self.alice.id  # Alice's ID is public: it's on every recipe she publishes
        recipe["title"] = "Hacked"
        self.assertEqual(self.call("PUT", f"/recipes/{recipe['id']}", recipe, forger)[0], 403)
        self.assertEqual(self.call("DELETE", f"/recipes/{recipe['id']}", user=forger)[0], 403)
        self.assertEqual(self.call("POST", "/recipes", make_recipe(), forger)[0], 403)

    def test_cannot_publish_as_someone_else(self):
        status, _ = self.call("POST", "/recipes", make_recipe(author_id=self.alice.id), self.bob)
        self.assertEqual(status, 403)

    def test_writes_require_credentials(self):
        self.assertEqual(self.call("POST", "/recipes", make_recipe())[0], 401)
        self.assertEqual(self.call("POST", "/recipes", make_recipe(),
                                   headers={"X-Author-ID": self.alice.id, "X-Author-Token": "short"})[0], 401)

    # Bad input -----------------------------------------------------------

    def test_duplicate_publish_conflicts(self):
        recipe = make_recipe()
        self.call("POST", "/recipes", recipe, self.alice)
        self.assertEqual(self.call("POST", "/recipes", recipe, self.alice)[0], 409)

    def test_missing_recipe_is_404(self):
        missing = str(uuid.uuid4()).upper()
        self.assertEqual(self.call("GET", f"/recipes/{missing}")[0], 404)
        self.assertEqual(self.call("PUT", f"/recipes/{missing}", make_recipe() | {"id": missing}, self.alice)[0], 404)
        self.assertEqual(self.call("DELETE", f"/recipes/{missing}", user=self.alice)[0], 404)

    def test_body_id_must_match_url(self):
        recipe = make_recipe()
        self.call("POST", "/recipes", recipe, self.alice)
        other = make_recipe()
        self.assertEqual(self.call("PUT", f"/recipes/{recipe['id']}", other, self.alice)[0], 400)

    def test_malformed_recipes_are_rejected(self):
        cases = {
            "blank title": {"title": "   "},
            "no ingredients": {"ingredients": []},
            "no steps": {"instructions": []},
            "bad ingredient id": {"ingredients": [{"id": "nope", "item": "Salt", "amount": "1"}]},
            "string number": {"prepTime": "10"},
            "bool number": {"servings": True},
            "bad image url": {"imageURL": "ftp://example.com/a.jpg"},
            "tags not list": {"tags": "Vegan"},
        }
        for name, change in cases.items():
            with self.subTest(name):
                recipe = make_recipe() | change
                status, body = self.call("POST", "/recipes", recipe, self.alice)
                self.assertEqual(status, 400, body)
        self.assertEqual(self.call("GET", "/recipes")[1], [])

    def test_invalid_json_is_rejected(self):
        request = urllib.request.Request(self.base + "/recipes", data=b"{not json", method="POST")
        for key, value in self.alice.headers().items():
            request.add_header(key, value)
        with self.assertRaises(urllib.error.HTTPError) as caught:
            urllib.request.urlopen(request)
        self.assertEqual(caught.exception.code, 400)

    def test_feed_only_contains_known_fields(self):
        recipe = make_recipe() | {"isAdmin": True, "secret": "x" * 10}
        _, published = self.call("POST", "/recipes", recipe, self.alice)
        self.assertNotIn("isAdmin", published)
        self.assertNotIn("secret", published)
        with open(self.data_path, encoding="utf-8") as handle:
            stored = json.load(handle)
        self.assertNotIn(self.alice.token, json.dumps(stored))  # only a hash is stored


if __name__ == "__main__":
    unittest.main(verbosity=2)
