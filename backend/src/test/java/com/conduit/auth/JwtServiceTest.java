package com.conduit.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.Date;
import java.util.Optional;
import javax.crypto.SecretKey;
import org.junit.jupiter.api.Test;

class JwtServiceTest {

    private static final String SECRET = "test_secret_change_me_64_bytes_min_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";

    @Test
    void createAndVerifyRoundTrip() {
        JwtService svc = new JwtService(SECRET, 168);
        String token = svc.create(42L);
        Optional<Long> verified = svc.verify(token);
        assertThat(verified).hasValue(42L);
    }

    @Test
    void verifyReturnsEmptyForTamperedSignature() {
        JwtService svc = new JwtService(SECRET, 168);
        String token = svc.create(42L);
        String tampered = token.substring(0, token.length() - 4) + "AAAA";
        assertThat(svc.verify(tampered)).isEmpty();
    }

    @Test
    void verifyReturnsEmptyForExpiredToken() {
        JwtService svc = new JwtService(SECRET, 168);
        SecretKey key = Keys.hmacShaKeyFor(SECRET.getBytes(StandardCharsets.UTF_8));
        Instant past = Instant.now().minus(Duration.ofDays(10));
        String expired =
                Jwts.builder()
                        .subject("42")
                        .issuedAt(Date.from(past))
                        .expiration(Date.from(past.plus(Duration.ofHours(1))))
                        .signWith(key)
                        .compact();
        assertThat(svc.verify(expired)).isEmpty();
    }

    @Test
    void verifyReturnsEmptyForGarbage() {
        JwtService svc = new JwtService(SECRET, 168);
        assertThat(svc.verify("not.a.jwt")).isEmpty();
    }

    @Test
    void constructorRejectsShortSecret() {
        assertThatThrownBy(() -> new JwtService("short_secret", 168))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("256 bits");
    }
}
