package com.conduit.profile;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.conduit.auth.JwtService;
import com.conduit.user.User;
import com.conduit.user.UserRepository;
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
class ProfileIT {

    @Autowired private MockMvc mockMvc;
    @Autowired private UserRepository userRepository;
    @Autowired private FollowRepository followRepository;
    @Autowired private PasswordEncoder passwordEncoder;
    @Autowired private JwtService jwtService;

    private String aliceToken;
    private long bobId;

    @BeforeEach
    void seed() {
        followRepository.deleteAll();
        userRepository.deleteAll();
        User alice = userRepository.save(
                new User("alice", "alice@example.com", passwordEncoder.encode("alice_pass")));
        User bob = userRepository.save(
                new User("bob", "bob@example.com", passwordEncoder.encode("bob_pass")));
        aliceToken = jwtService.create(alice.getId());
        bobId = bob.getId();
    }

    @Test
    void getProfileAnonymous() throws Exception {
        mockMvc.perform(get("/api/profiles/bob"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.profile.username").value("bob"))
                .andExpect(jsonPath("$.profile.following").value(false));
    }

    @Test
    void getProfileNotFound() throws Exception {
        mockMvc.perform(get("/api/profiles/nobody"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.errors.profile[0]").value("not found"));
    }

    @Test
    void followToggle() throws Exception {
        mockMvc.perform(post("/api/profiles/bob/follow").header("Authorization", "Token " + aliceToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.profile.following").value(true));

        // idempotent — same response on repeat
        mockMvc.perform(post("/api/profiles/bob/follow").header("Authorization", "Token " + aliceToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.profile.following").value(true));

        mockMvc.perform(delete("/api/profiles/bob/follow").header("Authorization", "Token " + aliceToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.profile.following").value(false));

        // idempotent — same response on repeat
        mockMvc.perform(delete("/api/profiles/bob/follow").header("Authorization", "Token " + aliceToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.profile.following").value(false));
    }

    @Test
    void followSelfReturns422() throws Exception {
        mockMvc.perform(post("/api/profiles/alice/follow").header("Authorization", "Token " + aliceToken))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.errors.username[0]").value("cannot follow self"));
    }

    @Test
    void followAnonymousReturns401() throws Exception {
        mockMvc.perform(post("/api/profiles/bob/follow")).andExpect(status().isUnauthorized());
    }
}
