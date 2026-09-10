package com.munserv.admin.repository

import com.munserv.TestContainersConfig
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.collections.shouldNotContain
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest
import org.springframework.boot.jdbc.test.autoconfigure.AutoConfigureTestDatabase
import org.springframework.context.annotation.Import
import org.springframework.test.context.ActiveProfiles
import java.time.Instant
import java.util.UUID

@DataJpaTest
@ActiveProfiles("test")
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Import(TestContainersConfig::class)
class JpaAdminRepositoryTest {
    @Autowired
    private lateinit var repository: SpringDataAdminRepository

    // Default pod ID from V003 migration, with ward and sector test accounts from V004 and V030
    private val defaultPodId = UUID.fromString("550e8400-e29b-41d4-a716-446655440000")

    @Test
    fun `should return pod level admins of the pod`() {
        val emails = repository.findAllInPod(defaultPodId).map { it.email }

        emails shouldContain "podchief@munserv.local"
    }

    @Test
    fun `should return ward level admins whose ward belongs to the pod`() {
        val emails = repository.findAllInPod(defaultPodId).map { it.email }

        emails shouldContain "wardadmin@munserv.local"
    }

    @Test
    fun `should return sector level admins whose sector belongs to the pod`() {
        val emails = repository.findAllInPod(defaultPodId).map { it.email }

        emails shouldContain "admin@ward42.example.com"
    }

    @Test
    fun `should not return deleted admins`() {
        val now = Instant.now()
        val deletedAdmin =
            AdminEntity(
                id = UUID.randomUUID(),
                podId = defaultPodId,
                email = "deleted-admin-test@munserv.local",
                passwordHash = "irrelevant-hash",
                displayName = "Deleted Test Admin",
                role = "pod_admin",
                createdAt = now,
                updatedAt = now,
                deletedAt = now,
            )
        repository.save(deletedAdmin)

        try {
            val emails = repository.findAllInPod(defaultPodId).map { it.email }

            emails shouldNotContain "deleted-admin-test@munserv.local"
        } finally {
            repository.deleteById(deletedAdmin.id)
        }
    }
}
