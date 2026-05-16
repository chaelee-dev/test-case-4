package com.conduit.article.dto;

import java.util.List;

public record UpdateArticleRequest(Wrapper article) {

    public record Wrapper(String title, String description, String body, List<String> tagList) {}
}
