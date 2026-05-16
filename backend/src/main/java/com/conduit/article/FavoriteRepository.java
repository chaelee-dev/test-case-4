package com.conduit.article;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.io.Serializable;
import java.time.Instant;
import java.util.List;
import java.util.Objects;
import org.springframework.data.jpa.repository.JpaRepository;

public interface FavoriteRepository extends JpaRepository<Favorite, Favorite.FavoriteId> {

    default boolean existsByUserAndArticle(long userId, long articleId) {
        return existsById(new Favorite.FavoriteId(userId, articleId));
    }

    default void removeIfExists(long userId, long articleId) {
        deleteById(new Favorite.FavoriteId(userId, articleId));
    }

    List<Favorite> findByIdArticleIdIn(List<Long> articleIds);
}

@Entity
@Table(name = "favorites")
class Favorite {
    @EmbeddedId FavoriteId id;

    @Column(name = "created_at", nullable = false, updatable = false)
    Instant createdAt;

    protected Favorite() {}

    public Favorite(long userId, long articleId) {
        this.id = new FavoriteId(userId, articleId);
    }

    @PrePersist
    void onCreate() {
        this.createdAt = Instant.now();
    }

    public FavoriteId getId() { return id; }

    @Embeddable
    public static class FavoriteId implements Serializable {
        @Column(name = "user_id") Long userId;
        @Column(name = "article_id") Long articleId;

        public FavoriteId() {}

        public FavoriteId(Long userId, Long articleId) {
            this.userId = userId;
            this.articleId = articleId;
        }

        public Long getUserId() { return userId; }
        public Long getArticleId() { return articleId; }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (!(o instanceof FavoriteId other)) return false;
            return Objects.equals(userId, other.userId) && Objects.equals(articleId, other.articleId);
        }

        @Override
        public int hashCode() {
            return Objects.hash(userId, articleId);
        }
    }
}
