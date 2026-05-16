package com.conduit.article;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.conduit.auth.JwtService;
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
class FavoriteIT {

    @Autowired private MockMvc mockMvc;
    @Autowired private UserRepository userRepository;
    @Autowired private ArticleRepository articleRepository;
    @Autowired private ArticleService articleService;
    @Autowired private PasswordEncoder passwordEncoder;
    @Autowired private JwtService jwtService;

    private String aliceToken;
    private String slug;

    @BeforeEach
    void seed() {
        articleRepository.deleteAll();
        userRepository.deleteAll();
        User alice = userRepository.save(
                new User("alice", "alice@example.com", passwordEncoder.encode("password")));
        User bob = userRepository.save(
                new User("bob", "bob@example.com", passwordEncoder.encode("password")));
        aliceToken = jwtService.create(alice.getId());
        slug = articleService.create(bob.getId(), "Bob Post", "intro", "body", List.of()).slug();
    }

    @Test
    void favoriteToggleCount() throws Exception {
        mockMvc.perform(post("/api/articles/" + slug + "/favorite").header("Authorization", "Token " + aliceToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.article.favorited").value(true))
                .andExpect(jsonPath("$.article.favoritesCount").value(1));

        // idempotent on repeat
        mockMvc.perform(post("/api/articles/" + slug + "/favorite").header("Authorization", "Token " + aliceToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.article.favorited").value(true))
                .andExpect(jsonPath("$.article.favoritesCount").value(1));

        mockMvc.perform(delete("/api/articles/" + slug + "/favorite").header("Authorization", "Token " + aliceToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.article.favorited").value(false))
                .andExpect(jsonPath("$.article.favoritesCount").value(0));

        // idempotent on unfavorite repeat
        mockMvc.perform(delete("/api/articles/" + slug + "/favorite").header("Authorization", "Token " + aliceToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.article.favoritesCount").value(0));
    }

    @Test
    void favoriteAnonymousReturns401() throws Exception {
        mockMvc.perform(post("/api/articles/" + slug + "/favorite")).andExpect(status().isUnauthorized());
    }

    @Test
    void favoriteUnknownSlugReturns404() throws Exception {
        mockMvc.perform(
                        post("/api/articles/no-such-slug/favorite").header("Authorization", "Token " + aliceToken))
                .andExpect(status().isNotFound());
    }
}
