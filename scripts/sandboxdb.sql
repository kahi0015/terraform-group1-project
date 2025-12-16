-- ==========================================================
--  Sandbox Platform Database Schema
--  Database: sandboxdb
-- ==========================================================

CREATE DATABASE IF NOT EXISTS sandboxdb;
USE sandboxdb;

-- ==========================================================
-- 1. user
-- ==========================================================
CREATE TABLE IF NOT EXISTS user (
    id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    email         VARCHAR(255) NOT NULL UNIQUE,
    display_name  VARCHAR(100),
    is_active     BOOLEAN DEFAULT TRUE,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================================
-- 2. sandbox
-- ==========================================================
CREATE TABLE IF NOT EXISTS sandbox (
    id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    state       ENUM('provisioning','active','failed','deleting','deleted') NOT NULL DEFAULT 'provisioning',
    region      VARCHAR(50),
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at  DATETIME NULL
);

-- ==========================================================
-- 3. sandbox_user (junction M:N)
-- ==========================================================
CREATE TABLE IF NOT EXISTS sandbox_user (
    user_id      BIGINT UNSIGNED NOT NULL,
    sandbox_id   BIGINT UNSIGNED NOT NULL,
    role         ENUM('owner','contributor','viewer') NOT NULL DEFAULT 'contributor',
    granted_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (user_id, sandbox_id),

    FOREIGN KEY (user_id)    REFERENCES user(id)    ON DELETE CASCADE,
    FOREIGN KEY (sandbox_id) REFERENCES sandbox(id) ON DELETE CASCADE
);

-- ==========================================================
-- 4. dataset
-- ==========================================================
CREATE TABLE IF NOT EXISTS dataset (
    id             BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sandbox_id     BIGINT UNSIGNED NOT NULL,
    uploaded_by    BIGINT UNSIGNED,
    name           VARCHAR(150) NOT NULL,
    storage_uri    TEXT NOT NULL,
    size_bytes     BIGINT UNSIGNED NOT NULL,
    uploaded_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (sandbox_id) REFERENCES sandbox(id) ON DELETE CASCADE,
    FOREIGN KEY (uploaded_by) REFERENCES user(id)   ON DELETE SET NULL
);

-- ==========================================================
-- 5. analysis_session
-- ==========================================================
CREATE TABLE IF NOT EXISTS analysis_session (
    id           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sandbox_id   BIGINT UNSIGNED NOT NULL,
    started_by   BIGINT UNSIGNED,
    tool         VARCHAR(100) NOT NULL,
    started_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ended_at     DATETIME NULL,

    FOREIGN KEY (sandbox_id) REFERENCES sandbox(id) ON DELETE CASCADE,
    FOREIGN KEY (started_by) REFERENCES user(id)    ON DELETE SET NULL
);

-- ==========================================================
-- 6. result
-- ==========================================================
CREATE TABLE IF NOT EXISTS result (
    id           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    session_id   BIGINT UNSIGNED NOT NULL,
    type         VARCHAR(50) NOT NULL,
    storage_uri  TEXT NOT NULL,
    created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (session_id) REFERENCES analysis_session(id) ON DELETE CASCADE
);

-- ==========================================================
-- 7. usage_log
-- ==========================================================
CREATE TABLE IF NOT EXISTS usage_log (
    id           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sandbox_id   BIGINT UNSIGNED NOT NULL,
    at           DATETIME NOT NULL,
    cpu_cores    DECIMAL(5,2) DEFAULT 0,
    ram_gb       DECIMAL(6,2) DEFAULT 0,
    storage_gb   DECIMAL(10,2) DEFAULT 0,
    est_cost     DECIMAL(10,4) DEFAULT 0,
    message      VARCHAR(255),

    FOREIGN KEY (sandbox_id) REFERENCES sandbox(id) ON DELETE CASCADE
);

-- ==========================================================
-- 8. provision_run
-- ==========================================================
CREATE TABLE IF NOT EXISTS provision_run (
    id           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sandbox_id   BIGINT UNSIGNED NOT NULL,
    action       ENUM('apply','destroy') NOT NULL,
    status       ENUM('running','success','failed') NOT NULL,
    tf_version   VARCHAR(50),
    started_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    finished_at  DATETIME NULL,

    FOREIGN KEY (sandbox_id) REFERENCES sandbox(id) ON DELETE CASCADE
);

-- ==========================================================
-- 9. sandbox_resource
-- ==========================================================
CREATE TABLE IF NOT EXISTS sandbox_resource (
    id                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sandbox_id        BIGINT UNSIGNED NOT NULL,
    run_id            BIGINT UNSIGNED NOT NULL,
    kind              VARCHAR(100) NOT NULL,
    azure_resource_id VARCHAR(500) NOT NULL,
    name              VARCHAR(150),
    state             VARCHAR(50),
    sku               VARCHAR(100),

    FOREIGN KEY (sandbox_id) REFERENCES sandbox(id) ON DELETE CASCADE,
    FOREIGN KEY (run_id)     REFERENCES provision_run(id) ON DELETE CASCADE
);
