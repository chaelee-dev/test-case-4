package com.conduit.web;

import com.conduit.article.ArticleService;
import com.conduit.article.dto.ArticleResponse;
import com.conduit.article.dto.ArticlesResponse;
import com.conduit.article.dto.NewArticleRequest;
import com.conduit.article.dto.UpdateArticleRequest;
import com.conduit.web.exception.AppException;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/articles")
public class ArticleController {

    private final ArticleService articleService;

    public ArticleController(ArticleService articleService) {
        this.articleService = articleService;
    }

    @PostMapping
    public ResponseEntity<ArticleResponse> create(
            @Valid @RequestBody NewArticleRequest request,
            @AuthenticationPrincipal Long viewerId) {
        if (viewerId == null) throw AppException.unauthorized("is invalid");
        var dto =
                articleService.create(
                        viewerId,
                        request.article().title(),
                        request.article().description(),
                        request.article().body(),
                        request.article().tagList());
        return ResponseEntity.status(HttpStatus.CREATED).body(new ArticleResponse(dto));
    }

    @GetMapping
    public ResponseEntity<ArticlesResponse> list(
            @RequestParam(required = false) String tag,
            @RequestParam(required = false) String author,
            @RequestParam(required = false) String favorited,
            @RequestParam(required = false) Integer limit,
            @RequestParam(required = false) Long offset,
            @AuthenticationPrincipal Long viewerId) {
        var page = Pagination.of(limit, offset);
        var result = articleService.list(tag, author, favorited, page, viewerId);
        return ResponseEntity.ok(new ArticlesResponse(result.articles(), result.total()));
    }

    @GetMapping("/feed")
    public ResponseEntity<ArticlesResponse> feed(
            @RequestParam(required = false) Integer limit,
            @RequestParam(required = false) Long offset,
            @AuthenticationPrincipal Long viewerId) {
        if (viewerId == null) throw AppException.unauthorized("is invalid");
        var page = Pagination.of(limit, offset);
        var result = articleService.feed(viewerId, page);
        return ResponseEntity.ok(new ArticlesResponse(result.articles(), result.total()));
    }

    @GetMapping("/{slug}")
    public ResponseEntity<ArticleResponse> get(
            @PathVariable String slug, @AuthenticationPrincipal Long viewerId) {
        return ResponseEntity.ok(new ArticleResponse(articleService.getBySlug(slug, viewerId)));
    }

    @PutMapping("/{slug}")
    public ResponseEntity<ArticleResponse> update(
            @PathVariable String slug,
            @RequestBody UpdateArticleRequest request,
            @AuthenticationPrincipal Long viewerId) {
        if (viewerId == null) throw AppException.unauthorized("is invalid");
        if (request.article() == null) {
            throw AppException.validation("article", "at least one field is required");
        }
        var a = request.article();
        var dto = articleService.update(viewerId, slug, a.title(), a.description(), a.body(), a.tagList());
        return ResponseEntity.ok(new ArticleResponse(dto));
    }

    @DeleteMapping("/{slug}")
    public ResponseEntity<Void> delete(
            @PathVariable String slug, @AuthenticationPrincipal Long viewerId) {
        if (viewerId == null) throw AppException.unauthorized("is invalid");
        articleService.delete(viewerId, slug);
        return ResponseEntity.noContent().build();
    }
}
