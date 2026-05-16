package com.conduit.comment.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;

public record NewCommentRequest(@Valid Wrapper comment) {

    public record Wrapper(@NotBlank(message = "can't be blank") String body) {}
}
