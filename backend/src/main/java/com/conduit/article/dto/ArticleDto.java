package com.conduit.article.dto;

import com.conduit.article.Article;
import com.conduit.profile.dto.ProfileDto;
import com.conduit.tag.Tag;
import java.time.Instant;
import java.util.List;

public record ArticleDto(
        String slug,
        String title,
        String description,
        String body,
        List<String> tagList,
        Instant createdAt,
        Instant updatedAt,
        boolean favorited,
        int favoritesCount,
        ProfileDto author) {

    public static ArticleDto from(Article article, boolean favorited, boolean followingAuthor) {
        return new ArticleDto(
                article.getSlug(),
                article.getTitle(),
                article.getDescription(),
                article.getBody(),
                article.getTags().stream().map(Tag::getName).sorted().toList(),
                article.getCreatedAt(),
                article.getUpdatedAt(),
                favorited,
                article.getFavoritesCount(),
                ProfileDto.from(article.getAuthor(), followingAuthor));
    }
}
