package com.munserv.members.service

import com.munserv.auth.domain.Member
import com.munserv.auth.repository.MemberRepository
import com.munserv.shared.types.MemberId
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

/**
 * Service for member profile operations.
 * Provides an abstraction layer between controllers and the repository.
 */
@Service
class MemberService(
    private val memberRepository: MemberRepository,
) {
    /**
     * Find a member by their ID.
     */
    @Transactional(readOnly = true)
    fun findById(id: MemberId): MemberResult =
        memberRepository
            .findById(id)
            ?.let { MemberResult.Success(it) }
            ?: MemberResult.NotFound(id)
}

/**
 * Sealed interface representing the possible results of member operations.
 */
sealed interface MemberResult {
    /**
     * Operation completed successfully.
     */
    data class Success(
        val member: Member,
    ) : MemberResult

    /**
     * Member was not found.
     */
    data class NotFound(
        val id: MemberId,
    ) : MemberResult
}
