;; Caregiver Verification Contract
;; Validates qualifications and background checks

(define-data-var admin principal tx-sender)

;; Map of registered caregivers
(define-map caregivers
{ caregiver-id: (string-ascii 32) }
{
  name: (string-ascii 64),
  contact-info: (string-ascii 128),
  professional-id: (string-ascii 32),
  specializations: (string-ascii 128),
  years-experience: uint,
  status: (string-ascii 16)
}
)

;; Map of caregiver qualifications
(define-map qualifications
{
  caregiver-id: (string-ascii 32),
  qualification-id: (string-ascii 32)
}
{
  qualification-type: (string-ascii 32),
  issuer: (string-ascii 64),
  issue-date: uint,
  expiry-date: uint,
  verification-status: (string-ascii 16)
}
)

;; Map of background checks
(define-map background-checks
{
  caregiver-id: (string-ascii 32),
  check-id: (string-ascii 32)
}
{
  check-type: (string-ascii 32),
  performed-by: (string-ascii 64),
  check-date: uint,
  result: (string-ascii 16)
}
)

;; Register a new caregiver
(define-public (register-caregiver
  (caregiver-id (string-ascii 32))
  (name (string-ascii 64))
  (contact-info (string-ascii 128))
  (professional-id (string-ascii 32))
  (specializations (string-ascii 128))
  (years-experience uint))
(begin
  (asserts! (not (is-some (map-get? caregivers { caregiver-id: caregiver-id }))) (err u403))

  (map-insert caregivers
    { caregiver-id: caregiver-id }
    {
      name: name,
      contact-info: contact-info,
      professional-id: professional-id,
      specializations: specializations,
      years-experience: years-experience,
      status: "pending"
    }
  )
  (ok true)
)
)

;; Update caregiver information
(define-public (update-caregiver
  (caregiver-id (string-ascii 32))
  (contact-info (string-ascii 128))
  (specializations (string-ascii 128))
  (years-experience uint))
(let ((caregiver (unwrap! (map-get? caregivers { caregiver-id: caregiver-id }) (err u404))))
  (asserts! (or (is-eq tx-sender (var-get admin)) (is-eq "caregiver" caregiver-id)) (err u403))

  (map-set caregivers
    { caregiver-id: caregiver-id }
    (merge caregiver {
      contact-info: contact-info,
      specializations: specializations,
      years-experience: years-experience
    })
  )
  (ok true)
)
)

;; Update caregiver status
(define-public (update-caregiver-status
  (caregiver-id (string-ascii 32))
  (status (string-ascii 16)))
(let ((caregiver (unwrap! (map-get? caregivers { caregiver-id: caregiver-id }) (err u404))))
  (asserts! (is-eq tx-sender (var-get admin)) (err u403))

  (map-set caregivers
    { caregiver-id: caregiver-id }
    (merge caregiver { status: status })
  )
  (ok true)
)
)

;; Add a qualification
(define-public (add-qualification
  (caregiver-id (string-ascii 32))
  (qualification-id (string-ascii 32))
  (qualification-type (string-ascii 32))
  (issuer (string-ascii 64))
  (issue-date uint)
  (expiry-date uint))
(begin
  (asserts! (is-some (map-get? caregivers { caregiver-id: caregiver-id })) (err u404))
  (asserts! (or (is-eq tx-sender (var-get admin)) (is-eq "caregiver" caregiver-id)) (err u403))

  (map-insert qualifications
    {
      caregiver-id: caregiver-id,
      qualification-id: qualification-id
    }
    {
      qualification-type: qualification-type,
      issuer: issuer,
      issue-date: issue-date,
      expiry-date: expiry-date,
      verification-status: "pending"
    }
  )
  (ok true)
)
)

;; Verify a qualification
(define-public (verify-qualification
  (caregiver-id (string-ascii 32))
  (qualification-id (string-ascii 32))
  (verification-status (string-ascii 16)))
(let ((qualification (unwrap! (map-get? qualifications { caregiver-id: caregiver-id, qualification-id: qualification-id }) (err u404))))
  (asserts! (is-eq tx-sender (var-get admin)) (err u403))

  (map-set qualifications
    {
      caregiver-id: caregiver-id,
      qualification-id: qualification-id
    }
    (merge qualification { verification-status: verification-status })
  )
  (ok true)
)
)

;; Record a background check
(define-public (record-background-check
  (caregiver-id (string-ascii 32))
  (check-id (string-ascii 32))
  (check-type (string-ascii 32))
  (performed-by (string-ascii 64))
  (check-date uint)
  (result (string-ascii 16)))
(begin
  (asserts! (is-some (map-get? caregivers { caregiver-id: caregiver-id })) (err u404))
  (asserts! (is-eq tx-sender (var-get admin)) (err u403))

  (map-insert background-checks
    {
      caregiver-id: caregiver-id,
      check-id: check-id
    }
    {
      check-type: check-type,
      performed-by: performed-by,
      check-date: check-date,
      result: result
    }
  )
  (ok true)
)
)

;; Get caregiver details
(define-read-only (get-caregiver (caregiver-id (string-ascii 32)))
(map-get? caregivers { caregiver-id: caregiver-id })
)

;; Get qualification details
(define-read-only (get-qualification (caregiver-id (string-ascii 32)) (qualification-id (string-ascii 32)))
(map-get? qualifications { caregiver-id: caregiver-id, qualification-id: qualification-id })
)

;; Get background check details
(define-read-only (get-background-check (caregiver-id (string-ascii 32)) (check-id (string-ascii 32)))
(map-get? background-checks { caregiver-id: caregiver-id, check-id: check-id })
)

;; Check if caregiver is verified
(define-read-only (is-caregiver-verified (caregiver-id (string-ascii 32)))
(let ((caregiver (map-get? caregivers { caregiver-id: caregiver-id })))
  (if (is-some caregiver)
    (is-eq (get status (unwrap-panic caregiver)) "verified")
    false
  )
)
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
(begin
  (asserts! (is-eq tx-sender (var-get admin)) (err u403))
  (var-set admin new-admin)
  (ok true)
)
)

