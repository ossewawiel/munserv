package com.munserv.pod.repository

import com.munserv.pod.domain.SetupStep
import com.munserv.shared.types.PodId
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.IdClass
import jakarta.persistence.Table
import java.io.Serializable
import java.time.Instant
import java.util.UUID

/**
 * Composite primary key for pod_setup_steps table.
 */
data class PodSetupStepId(
    val podId: UUID = UUID.randomUUID(),
    val step: String = "",
) : Serializable

/**
 * JPA entity for pod_setup_steps table.
 * Tracks which setup steps have been completed for each pod.
 */
@Entity
@Table(name = "pod_setup_steps")
@IdClass(PodSetupStepId::class)
class PodSetupStepEntity(
    @Id
    @Column(name = "pod_id", nullable = false)
    val podId: UUID,
    @Id
    @Column(name = "step", nullable = false, length = 50)
    val step: String,
    @Column(name = "completed_at", nullable = false)
    val completedAt: Instant,
) {
    /**
     * Convert to domain SetupStep.
     */
    fun toSetupStep(): SetupStep = SetupStep.fromDbValue(step)

    companion object {
        /**
         * Create entity from domain values.
         */
        fun create(
            podId: PodId,
            step: SetupStep,
            now: Instant,
        ): PodSetupStepEntity =
            PodSetupStepEntity(
                podId = podId.value,
                step = step.toDbValue(),
                completedAt = now,
            )
    }
}
