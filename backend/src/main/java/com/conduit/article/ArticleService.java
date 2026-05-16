package com.conduit.article;

import com.conduit.article.dto.ArticleDto;
import com.conduit.profile.FollowRepository;
import com.conduit.tag.Tag;
import com.conduit.tag.TagService;
import com.conduit.user.User;
import com.conduit.user.UserRepository;
import com.conduit.web.Pagination;
import com.conduit.web.exception.AppException;
import jakarta.persistence.criteria.Join;
import jakarta.persistence.criteria.JoinType;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ArticleService {

    private final ArticleRepository articleRepository;
    private final UserRepository userRepository;
    private final TagService tagService;
    private final SlugGenerator slugGenerator;
    private final FollowRepository followRepository;
    private final FavoriteRepository favoriteRepository;

    public ArticleService(
            ArticleRepository articleRepository,
            UserRepository userRepository,
            TagService tagService,
            SlugGenerator slugGenerator,
            FollowRepository followRepository,
            FavoriteRepository favoriteRepository) {
        this.articleRepository = articleRepository;
        this.userRepository = userRepository;
        this.tagService = tagService;
        this.slugGenerator = slugGenerator;
        this.followRepository = followRepository;
        this.favoriteRepository = favoriteRepository;
    }

    @Transactional
    public ArticleDto create(
            long authorId, String title, String description, String body, List<String> tagList) {
        User author = userRepository.findById(authorId).orElseThrow(() -> AppException.notFound("user"));
        String base = slugGenerator.slugify(title);
        String slug = base;
        if (articleRepository.existsBySlug(slug)) {
            slug = slugGenerator.withSuffix(base);
            int attempts = 0;
            while (articleRepository.existsBySlug(slug) && attempts < 5) {
                slug = slugGenerator.withSuffix(base);
                attempts++;
            }
            if (articleRepository.existsBySlug(slug)) {
                throw AppException.duplicate("slug", "could not generate unique slug");
            }
        }
        Article article = new Article(slug, title, description, body, author);
        if (tagList != null && !tagList.isEmpty()) {
            List<Tag> tags = tagService.upsertAll(tagList);
            article.setTags(new LinkedHashSet<>(tags));
        }
        articleRepository.save(article);
        return ArticleDto.from(article, false, false);
    }

    @Transactional(readOnly = true)
    public ListResult list(String tag, String authorUsername, String favoritedBy, Pagination page, Long viewerId) {
        if (page.isBeyondSafeCeiling()) {
            return new ListResult(List.of(), 0);
        }
        Specification<Article> spec = Specification.where(null);
        if (tag != null && !tag.isBlank()) {
            spec = spec.and(byTag(tag));
        }
        if (authorUsername != null && !authorUsername.isBlank()) {
            spec = spec.and(byAuthorUsername(authorUsername));
        }
        if (favoritedBy != null && !favoritedBy.isBlank()) {
            spec = spec.and(byFavoritedByUsername(favoritedBy));
        }
        var pageRequest =
                PageRequest.of(
                        (int) (page.offset() / Math.max(1, page.limit())),
                        page.limit(),
                        Sort.by(Sort.Direction.DESC, "createdAt"));
        var slice = articleRepository.findAll(spec, pageRequest);
        long total = articleRepository.count(spec);
        Set<Long> favoritedIds = viewerId == null ? Set.of() : favoritedArticleIds(viewerId, slice.toList());
        Set<Long> followingAuthorIds = viewerId == null ? Set.of() : followingAuthorIds(viewerId, slice.toList());
        List<ArticleDto> dtos =
                slice.stream()
                        .map(
                                a ->
                                        ArticleDto.from(
                                                a,
                                                favoritedIds.contains(a.getId()),
                                                followingAuthorIds.contains(a.getAuthor().getId())))
                        .toList();
        return new ListResult(dtos, total);
    }

    private Set<Long> favoritedArticleIds(long viewerId, List<Article> articles) {
        if (articles.isEmpty()) return Set.of();
        List<Long> ids = articles.stream().map(Article::getId).toList();
        Set<Long> favorited = new HashSet<>();
        for (Favorite f : favoriteRepository.findByIdArticleIdIn(ids)) {
            if (f.getId().getUserId() == viewerId) favorited.add(f.getId().getArticleId());
        }
        return favorited;
    }

    private Set<Long> followingAuthorIds(long viewerId, List<Article> articles) {
        if (articles.isEmpty()) return Set.of();
        Set<Long> result = new HashSet<>();
        for (Article a : articles) {
            if (followRepository.existsByFollowerAndFollowee(viewerId, a.getAuthor().getId())) {
                result.add(a.getAuthor().getId());
            }
        }
        return result;
    }

    private static Specification<Article> byTag(String tagName) {
        return (root, query, cb) -> {
            Join<Article, Tag> tags = root.join("tags", JoinType.INNER);
            return cb.equal(tags.get("name"), tagName);
        };
    }

    private static Specification<Article> byAuthorUsername(String username) {
        return (root, query, cb) -> cb.equal(root.get("author").get("username"), username);
    }

    private Specification<Article> byFavoritedByUsername(String username) {
        return (root, query, cb) -> {
            User favoriteUser = userRepository.findByUsername(username).orElse(null);
            if (favoriteUser == null) {
                return cb.disjunction(); // no matches
            }
            var subquery = query.subquery(Long.class);
            var fav = subquery.from(Favorite.class);
            subquery.select(fav.get("id").get("articleId"));
            subquery.where(cb.equal(fav.get("id").get("userId"), favoriteUser.getId()));
            return root.get("id").in(subquery);
        };
    }

    @Transactional(readOnly = true)
    public ListResult feed(long viewerId, Pagination page) {
        if (page.isBeyondSafeCeiling()) {
            return new ListResult(List.of(), 0);
        }
        Specification<Article> spec =
                (root, query, cb) -> {
                    var followSub = query.subquery(Long.class);
                    var followRoot =
                            followSub.from(com.conduit.profile.Follow.class);
                    followSub.select(followRoot.get("id").get("followeeId"));
                    followSub.where(cb.equal(followRoot.get("id").get("followerId"), viewerId));
                    return root.get("author").get("id").in(followSub);
                };
        var pageRequest =
                PageRequest.of(
                        (int) (page.offset() / Math.max(1, page.limit())),
                        page.limit(),
                        Sort.by(Sort.Direction.DESC, "createdAt"));
        var slice = articleRepository.findAll(spec, pageRequest);
        long total = articleRepository.count(spec);
        Set<Long> favoritedIds = favoritedArticleIds(viewerId, slice.toList());
        List<ArticleDto> dtos =
                slice.stream()
                        .map(a -> ArticleDto.from(a, favoritedIds.contains(a.getId()), true))
                        .toList();
        return new ListResult(dtos, total);
    }

    public record ListResult(List<ArticleDto> articles, long total) {}
}
