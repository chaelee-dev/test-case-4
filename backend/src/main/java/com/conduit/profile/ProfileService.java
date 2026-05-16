package com.conduit.profile;

import com.conduit.profile.dto.ProfileDto;
import com.conduit.user.User;
import com.conduit.user.UserRepository;
import com.conduit.web.exception.AppException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ProfileService {

    private final UserRepository userRepository;
    private final FollowRepository followRepository;

    public ProfileService(UserRepository userRepository, FollowRepository followRepository) {
        this.userRepository = userRepository;
        this.followRepository = followRepository;
    }

    @Transactional(readOnly = true)
    public ProfileDto getProfile(String username, Long viewerId) {
        User target = userRepository.findByUsername(username).orElseThrow(() -> AppException.notFound("profile"));
        boolean following = viewerId != null && followRepository.existsByFollowerAndFollowee(viewerId, target.getId());
        return ProfileDto.from(target, following);
    }

    @Transactional
    public ProfileDto follow(long followerId, String username) {
        User target = userRepository.findByUsername(username).orElseThrow(() -> AppException.notFound("profile"));
        if (target.getId() == followerId) {
            throw AppException.validation("username", "cannot follow self");
        }
        if (!followRepository.existsByFollowerAndFollowee(followerId, target.getId())) {
            followRepository.save(new Follow(followerId, target.getId()));
        }
        return ProfileDto.from(target, true);
    }

    @Transactional
    public ProfileDto unfollow(long followerId, String username) {
        User target = userRepository.findByUsername(username).orElseThrow(() -> AppException.notFound("profile"));
        followRepository.removeIfExists(followerId, target.getId());
        return ProfileDto.from(target, false);
    }
}
