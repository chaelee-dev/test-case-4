package com.conduit.profile;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.io.Serializable;
import java.time.Instant;
import java.util.Objects;

@Entity
@Table(name = "follows")
public class Follow {

    @EmbeddedId private FollowId id;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    protected Follow() {}

    public Follow(long followerId, long followeeId) {
        this.id = new FollowId(followerId, followeeId);
    }

    @PrePersist
    void onCreate() {
        this.createdAt = Instant.now();
    }

    public FollowId getId() { return id; }
    public Instant getCreatedAt() { return createdAt; }

    @Embeddable
    public static class FollowId implements Serializable {
        @Column(name = "follower_id")
        private Long followerId;

        @Column(name = "followee_id")
        private Long followeeId;

        public FollowId() {}

        public FollowId(Long followerId, Long followeeId) {
            this.followerId = followerId;
            this.followeeId = followeeId;
        }

        public Long getFollowerId() { return followerId; }
        public Long getFolloweeId() { return followeeId; }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (!(o instanceof FollowId other)) return false;
            return Objects.equals(followerId, other.followerId)
                    && Objects.equals(followeeId, other.followeeId);
        }

        @Override
        public int hashCode() {
            return Objects.hash(followerId, followeeId);
        }
    }
}
