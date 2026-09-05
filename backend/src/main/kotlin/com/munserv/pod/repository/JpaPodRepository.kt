package com.munserv.pod.repository

import com.munserv.pod.domain.Pod
import com.munserv.pod.domain.SetupStep
import com.munserv.shared.types.PodId
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.findByIdOrNull
import org.springframework.stereotype.Repository
import java.time.Clock
import java.time.Instant
import java.util.UUID

/**
 * Spring Data JPA repository for pods.
 */
interface SpringDataPodRepository : JpaRepository<PodEntity, UUID> {
    /**
     * Find the first pod ordered by creation date.
     * Used for MVP single-pod deployment.
     */
    fun findFirstByOrderByCreatedAtAsc(): PodEntity?
}

/**
 * Spring Data JPA repository for pod setup steps.
 */
interface SpringDataPodSetupStepRepository : JpaRepository<PodSetupStepEntity, PodSetupStepId> {
    @Query("SELECT e FROM PodSetupStepEntity e WHERE e.podId = :podId")
    fun findAllByPodId(podId: UUID): List<PodSetupStepEntity>

    @Query("SELECT COUNT(e) > 0 FROM PodSetupStepEntity e WHERE e.podId = :podId AND e.step = :step")
    fun existsByPodIdAndStep(
        podId: UUID,
        step: String,
    ): Boolean
}

/**
 * Implementation of PodRepository using Spring Data JPA.
 */
@Repository
class JpaPodRepository(
    private val springDataRepository: SpringDataPodRepository,
) : PodRepository {
    override fun findById(id: PodId): Pod? = springDataRepository.findByIdOrNull(id.value)?.toDomain()

    override fun findFirst(): Pod? = springDataRepository.findFirstByOrderByCreatedAtAsc()?.toDomain()

    override fun existsById(id: PodId): Boolean = springDataRepository.existsById(id.value)

    override fun save(pod: Pod): Pod = springDataRepository.save(PodEntity.fromDomain(pod)).toDomain()
}

/**
 * Implementation of PodSetupStepRepository using Spring Data JPA.
 */
@Repository
class JpaPodSetupStepRepository(
    private val springDataRepository: SpringDataPodSetupStepRepository,
    private val clock: Clock,
) : PodSetupStepRepository {
    override fun findCompletedSteps(podId: PodId): Set<SetupStep> =
        springDataRepository
            .findAllByPodId(podId.value)
            .map { it.toSetupStep() }
            .toSet()

    override fun isStepCompleted(
        podId: PodId,
        step: SetupStep,
    ): Boolean = springDataRepository.existsByPodIdAndStep(podId.value, step.toDbValue())

    override fun markComplete(
        podId: PodId,
        step: SetupStep,
    ) {
        if (!isStepCompleted(podId, step)) {
            val entity = PodSetupStepEntity.create(podId, step, Instant.now(clock))
            springDataRepository.save(entity)
        }
    }

    override fun isSetupComplete(podId: PodId): Boolean {
        val completedSteps = findCompletedSteps(podId)
        return completedSteps.containsAll(SetupStep.allRequired)
    }
}
