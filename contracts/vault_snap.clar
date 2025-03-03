;; VaultSnap - Secure Image Storage Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-invalid-hash (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-storage-limit (err u103))
(define-constant err-invalid-size (err u104))

;; Storage limits
(define-constant max-images-per-user u100)
(define-constant max-image-size u10000000) ;; 10MB limit

;; Data structures
(define-map images 
  { hash: (string-ascii 64) }
  {
    owner: principal,
    size: uint,
    timestamp: uint
  }
)

;; User statistics
(define-map user-stats
  { user: principal }
  {
    image-count: uint,
    total-size: uint
  }
)

;; Events
(define-data-var last-event-id uint u0)

(define-map events
  { id: uint }
  {
    event-type: (string-ascii 12),
    user: principal,
    hash: (string-ascii 64),
    timestamp: uint
  }
)

;; Helper functions
(define-private (emit-event (event-type (string-ascii 12)) (hash (string-ascii 64)))
  (let
    ((event-id (+ (var-get last-event-id) u1)))
    (map-set events
      { id: event-id }
      {
        event-type: event-type,
        user: tx-sender,
        hash: hash,
        timestamp: block-height
      }
    )
    (var-set last-event-id event-id)
    (ok event-id)
  )
)

(define-private (update-user-stats (user principal) (size uint) (is-addition bool))
  (let
    ((current-stats (default-to
      { image-count: u0, total-size: u0 }
      (map-get? user-stats { user: user }))))
    (map-set user-stats
      { user: user }
      {
        image-count: (if is-addition
          (+ (get image-count current-stats) u1)
          (- (get image-count current-stats) u1)),
        total-size: (if is-addition
          (+ (get total-size current-stats) size)
          (- (get total-size current-stats) size))
      }
    )
  )
)

;; Store new image metadata
(define-public (store-image (hash (string-ascii 64)) (size uint))
  (let
    ((existing-data (map-get? images {hash: hash}))
     (user-data (default-to
      { image-count: u0, total-size: u0 }
      (map-get? user-stats { user: tx-sender }))))
    (asserts! (<= size max-image-size) err-invalid-size)
    (asserts! (< (get image-count user-data) max-images-per-user) err-storage-limit)
    (if (is-some existing-data)
      err-already-exists
      (begin
        (try! (map-set images
          {hash: hash}
          {
            owner: tx-sender,
            size: size,
            timestamp: block-height
          }
        ))
        (update-user-stats tx-sender size true)
        (try! (emit-event "store" hash))
        (ok true)
      )
    )
  )
)

;; Verify image ownership
(define-read-only (verify-ownership (hash (string-ascii 64)) (owner principal))
  (let ((image-data (map-get? images {hash: hash})))
    (if (is-some image-data)
      (ok (is-eq (get owner (unwrap-panic image-data)) owner))
      (ok false)
    )
  )
)

;; Get image metadata
(define-read-only (get-image-data (hash (string-ascii 64)))
  (ok (map-get? images {hash: hash}))
)

;; Get user statistics
(define-read-only (get-user-stats (user principal))
  (ok (map-get? user-stats { user: user }))
)

;; Delete image metadata (owner only)
(define-public (delete-image (hash (string-ascii 64)))
  (let ((image-data (map-get? images {hash: hash})))
    (if (and
      (is-some image-data)
      (is-eq tx-sender (get owner (unwrap-panic image-data)))
    )
      (begin
        (map-delete images {hash: hash})
        (update-user-stats tx-sender (get size (unwrap-panic image-data)) false)
        (try! (emit-event "delete" hash))
        (ok true)
      )
      err-unauthorized
    )
  )
)
