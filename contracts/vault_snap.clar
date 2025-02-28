;; VaultSnap - Secure Image Storage Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-invalid-hash (err u101))
(define-constant err-already-exists (err u102))

;; Data structures
(define-map images 
  { hash: (string-ascii 64) }
  {
    owner: principal,
    size: uint,
    timestamp: uint
  }
)

;; Ownership tracking
(define-map image-owners
  { owner: principal }
  (list 100 (string-ascii 64))  
)

;; Store new image metadata
(define-public (store-image (hash (string-ascii 64)) (size uint))
  (let ((existing-data (map-get? images {hash: hash})))
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

;; Delete image metadata (owner only)
(define-public (delete-image (hash (string-ascii 64)))
  (let ((image-data (map-get? images {hash: hash})))
    (if (and
      (is-some image-data)
      (is-eq tx-sender (get owner (unwrap-panic image-data)))
    )
      (begin
        (map-delete images {hash: hash})
        (ok true)
      )
      err-unauthorized
    )
  )
)
