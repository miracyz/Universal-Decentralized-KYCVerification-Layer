;; title: Universal-Decentralized-KYCVerification-Layer

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ALREADY-VERIFIED (err u101))
(define-constant ERR-NOT-VERIFIED (err u102))
(define-constant ERR-INVALID-VERIFIER (err u103))
(define-constant ERR-ALREADY-REGISTERED (err u104))
(define-constant ERR-VERIFIER-NOT-FOUND (err u105))
(define-constant ERR-DAPP-ACCESS-DENIED (err u106))
(define-constant ERR-INVALID-HASH (err u107))
(define-constant ERR-EXPIRED-VERIFICATION (err u108))
(define-constant ERR-ALREADY-GRANTED (err u109))
(define-constant ERR-NOT-GRANTED (err u110))
(define-constant ERR-ALREADY-REPORTED (err u111))
(define-constant ERR-INSUFFICIENT-REPUTATION (err u112))
(define-constant ERR-INVALID-SLASH-AMOUNT (err u113))

(define-constant SLASHING-THRESHOLD u20)
(define-constant MIN-REPUTATION u10)

(define-data-var verification-fee uint u1000000)
(define-data-var verification-validity-period uint u52560)

(define-map verifiers
    principal
    {
        active: bool,
        registered-at: uint,
        verification-count: uint,
        reputation-score: uint
    }
)

(define-map user-verifications
    principal
    {
        verified: bool,
        verifier: principal,
        verified-at: uint,
        encrypted-data-hash: (buff 32),
        verification-level: uint,
        expiry-block: uint
    }
)

(define-map dapp-access-grants
    {user: principal, dapp: principal}
    {
        granted: bool,
        granted-at: uint,
        access-level: uint,
        expiry-block: uint
    }
)

(define-map dapp-registry
    principal
    {
        registered: bool,
        registered-at: uint,
        name: (string-ascii 50),
        category: (string-ascii 20)
    }
)

(define-map verification-requests
    {user: principal, verifier: principal}
    {
        pending: bool,
        requested-at: uint,
        data-hash: (buff 32)
    }
)

(define-map verifier-slashing-reports
    {reporter: principal, verifier: principal}
    {
        reported: bool,
        reported-at: uint,
        reason-hash: (buff 32),
        processed: bool
    }
)

(define-read-only (get-verifier (verifier principal))
    (map-get? verifiers verifier)
)

(define-read-only (get-user-verification (user principal))
    (map-get? user-verifications user)
)

(define-read-only (get-dapp-access (user principal) (dapp principal))
    (map-get? dapp-access-grants {user: user, dapp: dapp})
)

(define-read-only (get-dapp-info (dapp principal))
    (map-get? dapp-registry dapp)
)

(define-read-only (is-verified (user principal))
    (match (map-get? user-verifications user)
        verification (and 
            (get verified verification)
            (> (get expiry-block verification) stacks-block-height)
        )
        false
    )
)

(define-read-only (is-verifier (verifier principal))
    (match (map-get? verifiers verifier)
        verifier-data (get active verifier-data)
        false
    )
)

(define-read-only (has-dapp-access (user principal) (dapp principal))
    (match (map-get? dapp-access-grants {user: user, dapp: dapp})
        access (and 
            (get granted access)
            (> (get expiry-block access) stacks-block-height)
        )
        false
    )
)

(define-read-only (get-verification-fee)
    (ok (var-get verification-fee))
)

(define-read-only (get-verification-validity)
    (ok (var-get verification-validity-period))
)

(define-read-only (get-slashing-report (reporter principal) (verifier principal))
    (map-get? verifier-slashing-reports {reporter: reporter, verifier: verifier})
)

(define-read-only (is-verifier-slashable (verifier principal))
    (match (map-get? verifiers verifier)
        verifier-data (< (get reputation-score verifier-data) SLASHING-THRESHOLD)
        false
    )
)

(define-public (register-verifier)
    (let
        (
            (verifier tx-sender)
        )
        (asserts! (is-none (map-get? verifiers verifier)) ERR-ALREADY-REGISTERED)
        (map-set verifiers verifier {
            active: true,
            registered-at: stacks-block-height,
            verification-count: u0,
            reputation-score: u100
        })
        (ok true)
    )
)

(define-public (deactivate-verifier)
    (let
        (
            (verifier tx-sender)
        )
        (match (map-get? verifiers verifier)
            verifier-data (begin
                (map-set verifiers verifier (merge verifier-data {active: false}))
                (ok true)
            )
            ERR-VERIFIER-NOT-FOUND
        )
    )
)

(define-public (request-verification (verifier principal) (data-hash (buff 32)))
    (let
        (
            (user tx-sender)
        )
        (asserts! (is-verifier verifier) ERR-INVALID-VERIFIER)
        (asserts! (> (len data-hash) u0) ERR-INVALID-HASH)
        (map-set verification-requests {user: user, verifier: verifier} {
            pending: true,
            requested-at: stacks-block-height,
            data-hash: data-hash
        })
        (ok true)
    )
)

(define-public (verify-user (user principal) (encrypted-data-hash (buff 32)) (verification-level uint))
    (let
        (
            (verifier tx-sender)
            (expiry (+ stacks-block-height (var-get verification-validity-period)))
        )
        (asserts! (is-verifier verifier) ERR-INVALID-VERIFIER)
        (asserts! (> (len encrypted-data-hash) u0) ERR-INVALID-HASH)
        (match (map-get? user-verifications user)
            existing (asserts! (not (get verified existing)) ERR-ALREADY-VERIFIED)
            true
        )
        (map-set user-verifications user {
            verified: true,
            verifier: verifier,
            verified-at: stacks-block-height,
            encrypted-data-hash: encrypted-data-hash,
            verification-level: verification-level,
            expiry-block: expiry
        })
        (match (map-get? verifiers verifier)
            verifier-data (map-set verifiers verifier 
                (merge verifier-data {
                    verification-count: (+ (get verification-count verifier-data) u1),
                    reputation-score: (+ (get reputation-score verifier-data) u1)
                })
            )
            false
        )
        (ok true)
    )
)

(define-public (revoke-verification (user principal))
    (let
        (
            (caller tx-sender)
        )
        (match (map-get? user-verifications user)
            verification (begin
                (asserts! (or 
                    (is-eq caller (get verifier verification))
                    (is-eq caller CONTRACT-OWNER)
                    (is-eq caller user)
                ) ERR-NOT-AUTHORIZED)
                (map-set user-verifications user (merge verification {verified: false}))
                (ok true)
            )
            ERR-NOT-VERIFIED
        )
    )
)

(define-public (register-dapp (name (string-ascii 50)) (category (string-ascii 20)))
    (let
        (
            (dapp tx-sender)
        )
        (asserts! (is-none (map-get? dapp-registry dapp)) ERR-ALREADY-REGISTERED)
        (map-set dapp-registry dapp {
            registered: true,
            registered-at: stacks-block-height,
            name: name,
            category: category
        })
        (ok true)
    )
)

(define-public (grant-dapp-access (dapp principal) (access-level uint) (duration uint))
    (let
        (
            (user tx-sender)
            (expiry (+ stacks-block-height duration))
        )
        (asserts! (is-verified user) ERR-NOT-VERIFIED)
        (asserts! (is-some (map-get? dapp-registry dapp)) ERR-INVALID-VERIFIER)
        (match (map-get? dapp-access-grants {user: user, dapp: dapp})
            existing (asserts! (not (get granted existing)) ERR-ALREADY-GRANTED)
            true
        )
        (map-set dapp-access-grants {user: user, dapp: dapp} {
            granted: true,
            granted-at: stacks-block-height,
            access-level: access-level,
            expiry-block: expiry
        })
        (ok true)
    )
)

(define-public (revoke-dapp-access (dapp principal))
    (let
        (
            (user tx-sender)
        )
        (match (map-get? dapp-access-grants {user: user, dapp: dapp})
            access (begin
                (asserts! (get granted access) ERR-NOT-GRANTED)
                (map-set dapp-access-grants {user: user, dapp: dapp} 
                    (merge access {granted: false})
                )
                (ok true)
            )
            ERR-DAPP-ACCESS-DENIED
        )
    )
)

(define-public (renew-verification (encrypted-data-hash (buff 32)))
    (let
        (
            (user tx-sender)
            (expiry (+ stacks-block-height (var-get verification-validity-period)))
        )
        (match (map-get? user-verifications user)
            verification (begin
                (asserts! (get verified verification) ERR-NOT-VERIFIED)
                (map-set user-verifications user (merge verification {
                    verified-at: stacks-block-height,
                    encrypted-data-hash: encrypted-data-hash,
                    expiry-block: expiry
                }))
                (ok true)
            )
            ERR-NOT-VERIFIED
        )
    )
)

(define-public (update-verification-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (var-set verification-fee new-fee)
        (ok true)
    )
)

(define-public (update-verification-validity (new-validity uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (var-set verification-validity-period new-validity)
        (ok true)
    )
)

(define-public (report-verifier (verifier principal) (reason-hash (buff 32)))
    (let
        (
            (reporter tx-sender)
        )
        (asserts! (is-verifier verifier) ERR-INVALID-VERIFIER)
        (asserts! (> (len reason-hash) u0) ERR-INVALID-HASH)
        (asserts! (is-none (map-get? verifier-slashing-reports {reporter: reporter, verifier: verifier})) ERR-ALREADY-REPORTED)
        (map-set verifier-slashing-reports {reporter: reporter, verifier: verifier} {
            reported: true,
            reported-at: stacks-block-height,
            reason-hash: reason-hash,
            processed: false
        })
        (ok true)
    )
)

(define-public (slash-verifier (verifier principal) (slash-amount uint))
    (let
        (
            (caller tx-sender)
        )
        (asserts! (is-eq caller CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (asserts! (is-verifier verifier) ERR-INVALID-VERIFIER)
        (asserts! (> slash-amount u0) ERR-INVALID-SLASH-AMOUNT)
        (match (map-get? verifiers verifier)
            verifier-data 
                (let
                    (
                        (current-reputation (get reputation-score verifier-data))
                        (new-reputation (if (> current-reputation slash-amount)
                            (- current-reputation slash-amount)
                            u0
                        ))
                        (should-deactivate (< new-reputation MIN-REPUTATION))
                    )
                    (map-set verifiers verifier (merge verifier-data {
                        reputation-score: new-reputation,
                        active: (not should-deactivate)
                    }))
                    (ok true)
                )
            ERR-VERIFIER-NOT-FOUND
        )
    )
)
