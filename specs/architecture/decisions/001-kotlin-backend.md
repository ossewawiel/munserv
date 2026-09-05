# ADR-001: Kotlin + Spring Boot for the backend

**Date:** 2024-12 (recorded 2026-09-05)
**Status:** Accepted

## Context
The API serves a Flutter app and a React portal, needs mature security, JPA and PostGIS support, and must be easy for one maintainer and for agents to keep correct.

## Decision
Kotlin on Spring Boot (now 4.x on JVM 21), Hibernate with hibernate-spatial, Flyway migrations, springdoc OpenAPI. Domain code is pure Kotlin; framework annotations stop at the repository and API layers.

## Consequences
✅ Sealed classes and value classes make the result and type-safe id patterns natural.
✅ The Spring ecosystem covers security, mail, validation and OpenAPI without extra vendors.
⚠️ JVM start-up and Gradle builds are slower than a Node or Go service; CI mitigates with caching.
