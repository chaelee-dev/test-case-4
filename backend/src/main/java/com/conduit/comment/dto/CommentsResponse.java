package com.conduit.comment.dto;

import java.util.List;

public record CommentsResponse(List<CommentDto> comments) {}
