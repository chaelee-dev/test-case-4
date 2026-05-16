package com.conduit.comment.dto;

import com.conduit.comment.Comment;
import com.conduit.profile.dto.ProfileDto;
import java.time.Instant;

public record CommentDto(
        Long id, String body, Instant createdAt, Instant updatedAt, ProfileDto author) {

    public static CommentDto from(Comment c, boolean followingAuthor) {
        return new CommentDto(
                c.getId(),
                c.getBody(),
                c.getCreatedAt(),
                c.getUpdatedAt(),
                ProfileDto.from(c.getAuthor(), followingAuthor));
    }
}
