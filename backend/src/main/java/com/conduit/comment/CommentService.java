package com.conduit.comment;

import com.conduit.article.ArticleRepository;
import com.conduit.comment.dto.CommentDto;
import com.conduit.profile.FollowRepository;
import com.conduit.user.User;
import com.conduit.user.UserRepository;
import com.conduit.web.exception.AppException;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CommentService {

    private final CommentRepository commentRepository;
    private final ArticleRepository articleRepository;
    private final UserRepository userRepository;
    private final FollowRepository followRepository;

    public CommentService(
            CommentRepository commentRepository,
            ArticleRepository articleRepository,
            UserRepository userRepository,
            FollowRepository followRepository) {
        this.commentRepository = commentRepository;
        this.articleRepository = articleRepository;
        this.userRepository = userRepository;
        this.followRepository = followRepository;
    }

    @Transactional(readOnly = true)
    public List<CommentDto> list(String slug, Long viewerId) {
        var article = articleRepository.findBySlug(slug).orElseThrow(() -> AppException.notFound("article"));
        return commentRepository.findByArticleIdOrderByCreatedAtAsc(article.getId()).stream()
                .map(
                        c ->
                                CommentDto.from(
                                        c,
                                        viewerId != null
                                                && followRepository.existsByFollowerAndFollowee(
                                                        viewerId, c.getAuthor().getId())))
                .toList();
    }

    @Transactional
    public CommentDto create(long actorId, String slug, String body) {
        var article = articleRepository.findBySlug(slug).orElseThrow(() -> AppException.notFound("article"));
        User author = userRepository.findById(actorId).orElseThrow(() -> AppException.notFound("user"));
        Comment comment = new Comment(article, author, body);
        commentRepository.save(comment);
        return CommentDto.from(comment, false);
    }

    @Transactional
    public void delete(long actorId, String slug, long commentId) {
        var article = articleRepository.findBySlug(slug).orElseThrow(() -> AppException.notFound("article"));
        Comment comment = commentRepository.findById(commentId).orElseThrow(() -> AppException.notFound("comment"));
        if (!comment.getArticle().getId().equals(article.getId())) {
            throw AppException.notFound("comment");
        }
        if (comment.getAuthor().getId() != actorId) {
            throw AppException.forbidden("comment");
        }
        commentRepository.delete(comment);
    }
}
