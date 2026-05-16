package com.conduit.web;

import com.conduit.comment.CommentService;
import com.conduit.comment.dto.CommentResponse;
import com.conduit.comment.dto.CommentsResponse;
import com.conduit.comment.dto.NewCommentRequest;
import com.conduit.web.exception.AppException;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/articles/{slug}/comments")
public class CommentController {

    private final CommentService commentService;

    public CommentController(CommentService commentService) {
        this.commentService = commentService;
    }

    @GetMapping
    public ResponseEntity<CommentsResponse> list(
            @PathVariable String slug, @AuthenticationPrincipal Long viewerId) {
        return ResponseEntity.ok(new CommentsResponse(commentService.list(slug, viewerId)));
    }

    @PostMapping
    public ResponseEntity<CommentResponse> create(
            @PathVariable String slug,
            @Valid @RequestBody NewCommentRequest request,
            @AuthenticationPrincipal Long viewerId) {
        if (viewerId == null) throw AppException.unauthorized("is invalid");
        var dto = commentService.create(viewerId, slug, request.comment().body());
        return ResponseEntity.ok(new CommentResponse(dto));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(
            @PathVariable String slug,
            @PathVariable long id,
            @AuthenticationPrincipal Long viewerId) {
        if (viewerId == null) throw AppException.unauthorized("is invalid");
        commentService.delete(viewerId, slug, id);
        return ResponseEntity.noContent().build();
    }
}
