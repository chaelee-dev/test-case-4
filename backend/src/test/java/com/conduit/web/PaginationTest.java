package com.conduit.web;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.conduit.web.exception.AppException;
import org.junit.jupiter.api.Test;

class PaginationTest {

    @Test
    void defaultsWhenNullsProvided() {
        Pagination p = Pagination.of(null, null);
        assertThat(p.limit()).isEqualTo(20);
        assertThat(p.offset()).isZero();
        assertThat(p.isBeyondSafeCeiling()).isFalse();
    }

    @Test
    void clampsHugeLimitToMax() {
        Pagination p = Pagination.of(500, 0L);
        assertThat(p.limit()).isEqualTo(100);
    }

    @Test
    void zeroLimitRejected() {
        assertThatThrownBy(() -> Pagination.of(0, 0L))
                .isInstanceOf(AppException.class)
                .hasMessageContaining("must be at least 1");
    }

    @Test
    void negativeLimitRejected() {
        assertThatThrownBy(() -> Pagination.of(-5, 0L)).isInstanceOf(AppException.class);
    }

    @Test
    void negativeOffsetRejected() {
        assertThatThrownBy(() -> Pagination.of(20, -1L))
                .isInstanceOf(AppException.class)
                .hasMessageContaining("must be non-negative");
    }

    @Test
    void hugeOffsetIsSafeButFlagged() {
        Pagination p = Pagination.of(20, 5_000_000L);
        assertThat(p.offset()).isEqualTo(5_000_000L);
        assertThat(p.isBeyondSafeCeiling()).isTrue();
    }
}
