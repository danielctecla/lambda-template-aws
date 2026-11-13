import assert from "node:assert/strict";
import { test } from "node:test";

import { handler } from "../../src/nodejs/index.mjs";

test("returns 200 JSON", async () => {
  const response = await handler({ path: "/orders" });

  assert.equal(response.statusCode, 200);
  assert.equal(response.headers["Content-Type"], "application/json");
});

test("body includes message and path", async () => {
  const body = JSON.parse((await handler({ path: "/orders" })).body);

  assert.equal(body.message, "Hello from Node.js Lambda!");
  assert.equal(body.path, "/orders");
});

test("uses rawPath for HTTP API events", async () => {
  const body = JSON.parse((await handler({ rawPath: "/orders" })).body);

  assert.equal(body.path, "/orders");
});

test("path is null when missing", async () => {
  const body = JSON.parse((await handler({})).body);

  assert.equal(body.path, null);
});
