package com.conduit.article;

import com.conduit.article.dto.ArticleDto;
import com.conduit.tag.Tag;
import com.conduit.tag.TagService;
import com.conduit.user.User;
import com.conduit.user.UserRepository;
import com.conduit.web.exception.AppException;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ArticleService {

    private final ArticleRepository articleRepository;
    private final UserRepository userRepository;
    private final TagService tagService;
    private final SlugGenerator slugGenerator;

    public ArticleService(
            ArticleRepository articleRepository,
            UserRepository userRepository,
            TagService tagService,
            SlugGenerator slugGenerator) {
        this.articleRepository = articleRepository;
        this.userRepository = userRepository;
        this.tagService = tagService;
        this.slugGenerator = slugGenerator;
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
}
