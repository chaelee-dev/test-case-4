package com.conduit.article.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import java.util.List;

public record NewArticleRequest(@Valid Wrapper article) {

    public record Wrapper(
            @NotBlank(message = "can't be blank") String title,
            @NotBlank(message = "can't be blank") String description,
            @NotBlank(message = "can't be blank") String body,
            List<String> tagList) {}
}
