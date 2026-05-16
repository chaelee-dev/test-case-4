package com.conduit.article;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.conduit.auth.JwtService;
import com.conduit.profile.FollowRepository;
import com.conduit.tag.TagRepository;
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
class ArticleFeedIT {

    @Autowired private MockMvc mockMvc;
    @Autowired private UserRepository userRepository;
    @Autowired private ArticleRepository articleRepository;
    @Autowired private TagRepository tagRepository;
    @Autowired private FollowRepository followRepository;
    @Autowired private ArticleService articleService;
    @Autowired private PasswordEncoder passwordEncoder;
    @Autowired private JwtService jwtService;

    private String aliceToken;

    @BeforeEach
    void seed() {
        followRepository.deleteAll();
        articleRepository.deleteAll();
        tagRepository.deleteAll();
        userRepository.deleteAll();
        User alice = userRepository.save(
                new User("alice", "alice@example.com", passwordEncoder.encode("password")));
        User bob = userRepository.save(
                new User("bob", "bob@example.com", passwordEncoder.encode("password")));
        User carol = userRepository.save(
                new User("carol", "carol@example.com", passwordEncoder.encode("password")));
        aliceToken = jwtService.create(alice.getId());
        articleService.create(bob.getId(), "Bob One", "intro", "body", List.of("react"));
        articleService.create(bob.getId(), "Bob Two", "intro", "body", List.of("java"));
        articleService.create(carol.getId(), "Carol One", "intro", "body", List.of("react"));
    }

    @Test
    void emptyFeedWhenFollowingNobody() throws Exception {
        mockMvc.perform(get("/api/articles/feed").header("Authorization", "Token " + aliceToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.articlesCount").value(0));
    }

    @Test
    void feedReflectsFollows() throws Exception {
        // alice follows bob
        mockMvc.perform(post("/api/profiles/bob/follow").header("Authorization", "Token " + aliceToken))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/articles/feed").header("Authorization", "Token " + aliceToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.articlesCount").value(2))
                .andExpect(jsonPath("$.articles[0].author.username").value("bob"))
                .andExpect(jsonPath("$.articles[0].author.following").value(true));
    }

    @Test
    void feedRequiresAuth() throws Exception {
        mockMvc.perform(get("/api/articles/feed")).andExpect(status().isUnauthorized());
    }
}
