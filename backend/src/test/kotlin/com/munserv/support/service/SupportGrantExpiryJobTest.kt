package com.munserv.support.service

import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.junit.jupiter.api.Test

class SupportGrantExpiryJobTest {
    private val supportAccessService: SupportAccessService = mockk()
    private val job = SupportGrantExpiryJob(supportAccessService)

    @Test
    fun `should delegate to expireStaleGrants when the job runs`() {
        every { supportAccessService.expireStaleGrants() } returns 3

        job.run()

        verify(exactly = 1) { supportAccessService.expireStaleGrants() }
    }
}
