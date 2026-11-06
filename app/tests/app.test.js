const test = require("node:test");
const assert = require("node:assert/strict");
const request = require("supertest");
const { createApp } = require("../src/app");

function createFakeDb() {
  const records = [];

  return {
    records,

    async command() {
      return { ok: 1 };
    },

    collection() {
      return {
        async insertOne(document) {
          const record = {
            _id: `test-${records.length + 1}`,
            ...document
          };

          records.push(record);

          return { insertedId: record._id };
        },

        find() {
          return {
            limit() {
              return {
                async toArray() {
                  return records;
                }
              };
            }
          };
        }
      };
    }
  };
}

test("GET /health returns healthy", async () => {
  const app = createApp(createFakeDb());

  const response = await request(app).get("/health");

  assert.equal(response.status, 200);
  assert.equal(response.body.status, "healthy");
});

test("GET /ready confirms database connectivity", async () => {
  const app = createApp(createFakeDb());

  const response = await request(app).get("/ready");

  assert.equal(response.status, 200);
  assert.equal(response.body.database, "connected");
});

test("POST /api/students creates a record", async () => {
  const app = createApp(createFakeDb());

  const response = await request(app)
    .post("/api/students")
    .send({
      referenceId: "ASSESSMENT-001",
      name: "Demo Student"
    });

  assert.equal(response.status, 201);
  assert.equal(response.body.message, "Student record created");
});

test("POST /api/students rejects missing fields", async () => {
  const app = createApp(createFakeDb());

  const response = await request(app)
    .post("/api/students")
    .send({ name: "Demo Student" });

  assert.equal(response.status, 400);
});
