package com.conduit.article.dto;

import java.util.List;

public record ArticlesResponse(List<ArticleDto> articles, long articlesCount) {}
