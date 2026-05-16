import http from "k6/http";
import { check, sleep } from "k6";

// P1: single user response time — 19 endpoints sampled. Target: 95p < 300ms.
export const options = {
  vus: 1,
  duration: "1m",
  thresholds: {
    http_req_duration: ["p(95)<300"],
    http_req_failed: ["rate<0.01"],
  },
};

const BASE = __ENV.BASE_URL || "http://localhost:8080/api";

export default function () {
  const responses = http.batch([
    ["GET", `${BASE}/health`],
    ["GET", `${BASE}/articles?limit=20`],
    ["GET", `${BASE}/tags`],
  ]);
  responses.forEach((r) => check(r, { "status is 2xx": (res) => res.status >= 200 && res.status < 300 }));
  sleep(1);
}
