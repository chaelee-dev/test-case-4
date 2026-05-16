import http from "k6/http";
import { check } from "k6";

// P3: huge offset safety — single request offset=5_000_000 must complete < 500ms
// with empty result (R-N-07).
export const options = {
  vus: 1,
  iterations: 5,
  thresholds: {
    http_req_duration: ["p(95)<500"],
  },
};

const BASE = __ENV.BASE_URL || "http://localhost:8080/api";

export default function () {
  const res = http.get(`${BASE}/articles?offset=5000000`);
  check(res, {
    "200 OK": (r) => r.status === 200,
    "empty articles": (r) => JSON.parse(r.body).articles.length === 0,
  });
}
