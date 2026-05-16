package com.conduit.profile;

import org.springframework.data.jpa.repository.JpaRepository;

public interface FollowRepository extends JpaRepository<Follow, Follow.FollowId> {

    default boolean existsByFollowerAndFollowee(long followerId, long followeeId) {
        return existsById(new Follow.FollowId(followerId, followeeId));
    }

    default void removeIfExists(long followerId, long followeeId) {
        deleteById(new Follow.FollowId(followerId, followeeId));
    }
}
