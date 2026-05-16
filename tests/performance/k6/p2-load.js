import http from "k6/http";
import { check } from "k6";

// P2: 50 VUs hitting article list for 5 min. Target: 95p < 500ms, error < 1%.
// Seeds 10k articles via /api separately; this scenario only reads.
export const options = {
  stages: [
    { duration: "30s", target: 10 },
    { duration: "1m", target: 50 },
    { duration: "3m", target: 50 },
    { duration: "30s", target: 0 },
  ],
  thresholds: {
    http_req_duration: ["p(95)<500"],
    http_req_failed: ["rate<0.01"],
  },
};

const BASE = __ENV.BASE_URL || "http://localhost:8080/api";

export default function () {
  const offset = Math.floor(Math.random() * 100) * 20;
  const res = http.get(`${BASE}/articles?limit=20&offset=${offset}`);
  check(res, { "200 OK": (r) => r.status === 200 });
}
