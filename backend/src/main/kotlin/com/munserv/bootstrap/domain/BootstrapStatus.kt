package com.munserv.bootstrap.domain

/**
 * Represents the bootstrap eligibility status of a pod.
 *
 * Used to determine whether the super user can create the first Pod Chief
 * or if the pod has already been bootstrapped.
 */
sealed class BootstrapStatus {
    /**
     * Pod is eligible for bootstrap - no Pod Chief exists yet.
     * Super user can create the first Pod Chief.
     */
    data object Eligible : BootstrapStatus()

    /**
     * Pod Chief exists but hasn't completed onboarding yet.
     * Super user access is blocked while Pod Chief completes onboarding.
     */
    data object PodChiefOnboarding : BootstrapStatus()

    /**
     * Pod Chief exists and has completed onboarding.
     * Bootstrap is no longer available.
     */
    data object NotEligible : BootstrapStatus()

    /**
     * Returns true if super user can access the pod for bootstrap.
     */
    val canBootstrap: Boolean
        get() = this is Eligible
}
