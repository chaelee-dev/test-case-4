package com.conduit.article;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.conduit.tag.TagRepository;
import com.conduit.tag.TagService;
import com.conduit.user.User;
import com.conduit.user.UserRepository;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class ArticleListIT {

    @Autowired private MockMvc mockMvc;
    @Autowired private UserRepository userRepository;
    @Autowired private ArticleRepository articleRepository;
    @Autowired private TagRepository tagRepository;
    @Autowired private TagService tagService;
    @Autowired private ArticleService articleService;
    @Autowired private PasswordEncoder passwordEncoder;

    @BeforeEach
    void seed() {
        articleRepository.deleteAll();
        tagRepository.deleteAll();
        userRepository.deleteAll();
        User alice = userRepository.save(
                new User("alice", "alice@example.com", passwordEncoder.encode("password")));
        User bob = userRepository.save(
                new User("bob", "bob@example.com", passwordEncoder.encode("password")));
        articleService.create(alice.getId(), "Alice Post One", "intro", "body", List.of("react"));
        articleService.create(alice.getId(), "Alice Post Two", "intro", "body", List.of("java"));
        articleService.create(bob.getId(), "Bob Post", "intro", "body", List.of("react", "go"));
    }

    @Test
    void anonymousListReturnsAllArticles() throws Exception {
        mockMvc.perform(get("/api/articles"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.articlesCount").value(3))
                .andExpect(jsonPath("$.articles.length()").value(3));
    }

    @Test
    void filterByTagReturnsMatchingOnly() throws Exception {
        mockMvc.perform(get("/api/articles").param("tag", "react"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.articlesCount").value(2))
                .andExpect(jsonPath("$.articles[0].tagList[?(@==\"react\")]").exists());
    }

    @Test
    void filterByAuthorReturnsMatching() throws Exception {
        mockMvc.perform(get("/api/articles").param("author", "bob"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.articlesCount").value(1))
                .andExpect(jsonPath("$.articles[0].author.username").value("bob"));
    }

    @Test
    void paginationLimit() throws Exception {
        mockMvc.perform(get("/api/articles").param("limit", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.articles.length()").value(2))
                .andExpect(jsonPath("$.articlesCount").value(3));
    }

    @Test
    void invalidOffsetReturns422() throws Exception {
        mockMvc.perform(get("/api/articles").param("offset", "-1"))
                .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void hugeOffsetReturnsEmpty() throws Exception {
        mockMvc.perform(get("/api/articles").param("offset", "5000000"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.articles.length()").value(0));
    }
}
