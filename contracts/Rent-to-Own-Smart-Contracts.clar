(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ASSET_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_ENROLLED (err u102))
(define-constant ERR_NOT_ENROLLED (err u103))
(define-constant ERR_PAYMENT_AMOUNT (err u104))
(define-constant ERR_PAYMENT_LATE (err u105))
(define-constant ERR_ALREADY_OWNED (err u106))
(define-constant ERR_INSUFFICIENT_PAYMENT (err u107))

(define-map assets
  { asset-id: uint }
  {
    owner: principal,
    tenant: (optional principal),
    total-value: uint,
    payment-amount: uint,
    payment-interval: uint,
    payments-made: uint,
    total-payments: uint,
    last-payment-block: uint,
    active: bool
  }
)

(define-map tenant-assets
  { tenant: principal }
  { asset-ids: (list 10 uint) }
)

(define-data-var asset-counter uint u0)

(define-read-only (get-asset (asset-id uint))
  (map-get? assets { asset-id: asset-id })
)

(define-read-only (get-tenant-assets (tenant principal))
  (default-to { asset-ids: (list) } (map-get? tenant-assets { tenant: tenant }))
)

(define-read-only (calculate-ownership-percentage (asset-id uint))
  (match (map-get? assets { asset-id: asset-id })
    asset-data
    (if (> (get total-payments asset-data) u0)
      (/ (* (get payments-made asset-data) u100) (get total-payments asset-data))
      u0)
    u0
  )
)

(define-read-only (is-payment-due (asset-id uint))
  (match (map-get? assets { asset-id: asset-id })
    asset-data
    (let ((blocks-since-last (- stacks-block-height (get last-payment-block asset-data))))
      (>= blocks-since-last (get payment-interval asset-data)))
    false
  )
)

(define-public (create-asset (total-value uint) (payment-amount uint) (payment-interval uint))
  (let ((asset-id (+ (var-get asset-counter) u1))
        (total-payments (/ total-value payment-amount)))
    (asserts! (> total-value u0) ERR_PAYMENT_AMOUNT)
    (asserts! (> payment-amount u0) ERR_PAYMENT_AMOUNT)
    (asserts! (> payment-interval u0) ERR_PAYMENT_AMOUNT)
    (map-set assets
      { asset-id: asset-id }
      {
        owner: tx-sender,
        tenant: none,
        total-value: total-value,
        payment-amount: payment-amount,
        payment-interval: payment-interval,
        payments-made: u0,
        total-payments: total-payments,
        last-payment-block: u0,
        active: true
      }
    )
    (var-set asset-counter asset-id)
    (ok asset-id)
  )
)

(define-public (enroll-tenant (asset-id uint))
  (match (map-get? assets { asset-id: asset-id })
    asset-data
    (begin
      (asserts! (get active asset-data) ERR_ASSET_NOT_FOUND)
      (asserts! (is-none (get tenant asset-data)) ERR_ALREADY_ENROLLED)
      (map-set assets
        { asset-id: asset-id }
        (merge asset-data { tenant: (some tx-sender), last-payment-block: stacks-block-height })
      )
      (let ((current-assets (get asset-ids (get-tenant-assets tx-sender))))
        (map-set tenant-assets
          { tenant: tx-sender }
          { asset-ids: (unwrap! (as-max-len? (append current-assets asset-id) u10) ERR_INSUFFICIENT_PAYMENT) }
        )
      )
      (ok true)
    )
    ERR_ASSET_NOT_FOUND
  )
)

(define-public (make-payment (asset-id uint))
  (match (map-get? assets { asset-id: asset-id })
    asset-data
    (let ((tenant (unwrap! (get tenant asset-data) ERR_NOT_ENROLLED)))
      (asserts! (is-eq tx-sender tenant) ERR_UNAUTHORIZED)
      (asserts! (get active asset-data) ERR_ASSET_NOT_FOUND)
      (asserts! (< (get payments-made asset-data) (get total-payments asset-data)) ERR_ALREADY_OWNED)
      (asserts! (is-payment-due asset-id) ERR_PAYMENT_LATE)
      
      (try! (stx-transfer? (get payment-amount asset-data) tx-sender (get owner asset-data)))
      
      (let ((new-payments (+ (get payments-made asset-data) u1))
            (is-final-payment (>= new-payments (get total-payments asset-data))))
        (map-set assets
          { asset-id: asset-id }
          (merge asset-data 
            {
              payments-made: new-payments,
              last-payment-block: stacks-block-height,
              owner: (if is-final-payment tx-sender (get owner asset-data)),
              tenant: (if is-final-payment none (some tx-sender)),
              active: (not is-final-payment)
            }
          )
        )
        (if is-final-payment
          (ok { transferred: true, payments-remaining: u0 })
          (ok { transferred: false, payments-remaining: (- (get total-payments asset-data) new-payments) })
        )
      )
    )
    ERR_ASSET_NOT_FOUND
  )
)

(define-public (cancel-contract (asset-id uint))
  (match (map-get? assets { asset-id: asset-id })
    asset-data
    (begin
      (asserts! (is-eq tx-sender (get owner asset-data)) ERR_UNAUTHORIZED)
      (asserts! (get active asset-data) ERR_ASSET_NOT_FOUND)
      (map-set assets
        { asset-id: asset-id }
        (merge asset-data { active: false, tenant: none })
      )
      (ok true)
    )
    ERR_ASSET_NOT_FOUND
  )
)

(define-public (withdraw-payments (asset-id uint))
  (match (map-get? assets { asset-id: asset-id })
    asset-data
    (let ((total-received (* (get payments-made asset-data) (get payment-amount asset-data))))
      (asserts! (is-eq tx-sender (get owner asset-data)) ERR_UNAUTHORIZED)
      (asserts! (> (get payments-made asset-data) u0) ERR_INSUFFICIENT_PAYMENT)
      (ok total-received)
    )
    ERR_ASSET_NOT_FOUND
  )
)

(define-read-only (get-contract-stats)
  {
    total-assets: (var-get asset-counter),
    contract-owner: CONTRACT_OWNER
  }
)

(define-read-only (get-payment-status (asset-id uint))
  (match (map-get? assets { asset-id: asset-id })
    asset-data
    (ok {
      payments-made: (get payments-made asset-data),
      total-payments: (get total-payments asset-data),
      next-payment-due: (+ (get last-payment-block asset-data) (get payment-interval asset-data)),
      ownership-percentage: (calculate-ownership-percentage asset-id),
      is-complete: (>= (get payments-made asset-data) (get total-payments asset-data))
    })
    ERR_ASSET_NOT_FOUND
  )
)
