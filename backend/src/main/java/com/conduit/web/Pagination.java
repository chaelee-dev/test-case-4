package com.conduit.web;

import com.conduit.web.exception.AppException;

/** Pagination guardrails per R-N-07: negative → 422, limit clamp(100), huge offset → safe empty. */
public final class Pagination {

    public static final int DEFAULT_LIMIT = 20;
    public static final int MAX_LIMIT = 100;
    public static final long SAFE_OFFSET_CEILING = 1_000_000L;

    private final int limit;
    private final long offset;

    private Pagination(int limit, long offset) {
        this.limit = limit;
        this.offset = offset;
    }

    public int limit() { return limit; }
    public long offset() { return offset; }

    public boolean isBeyondSafeCeiling() {
        return offset >= SAFE_OFFSET_CEILING;
    }

    public static Pagination of(Integer requestedLimit, Long requestedOffset) {
        int normalizedLimit;
        if (requestedLimit == null) {
            normalizedLimit = DEFAULT_LIMIT;
        } else if (requestedLimit < 1) {
            throw AppException.validation("limit", "must be at least 1");
        } else {
            normalizedLimit = Math.min(requestedLimit, MAX_LIMIT);
        }

        long normalizedOffset;
        if (requestedOffset == null) {
            normalizedOffset = 0;
        } else if (requestedOffset < 0) {
            throw AppException.validation("offset", "must be non-negative");
        } else {
            normalizedOffset = requestedOffset;
        }

        return new Pagination(normalizedLimit, normalizedOffset);
    }
}
