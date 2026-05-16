plugins {
    java
    id("org.springframework.boot") version "3.4.5"
    id("io.spring.dependency-management") version "1.1.6"
}

group = "com.conduit"
version = "0.1.0"

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}

repositories {
    mavenCentral()
}

dependencies {
    // Spring Boot core
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-validation")
    implementation("org.springframework.boot:spring-boot-starter-actuator")

    // Security + JWT (Issue #2)
    implementation("org.springframework.boot:spring-boot-starter-security")
    implementation("io.jsonwebtoken:jjwt-api:0.12.6")
    runtimeOnly("io.jsonwebtoken:jjwt-impl:0.12.6")
    runtimeOnly("io.jsonwebtoken:jjwt-jackson:0.12.6")

    // Data JPA (Issue #4)
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")

    // Reserved for I-17+
    // implementation("org.commonmark:commonmark:0.22.0")
    // implementation("org.jsoup:jsoup:1.18.1")

    testImplementation("org.springframework.security:spring-security-test")

    // Database — Flyway baseline only for bootstrap; entities arrive in I-04+
    runtimeOnly("org.postgresql:postgresql")
    implementation("org.flywaydb:flyway-core")
    implementation("org.flywaydb:flyway-database-postgresql")

    // Testing
    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testRuntimeOnly("com.h2database:h2")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}

tasks.withType<Test> {
    useJUnitPlatform()
}

tasks.bootJar {
    archiveBaseName.set("conduit-api")
    archiveVersion.set(project.version.toString())
}

// Reproducible dependency resolution — locks emitted to gradle.lockfile
dependencyLocking {
    lockAllConfigurations()
}
