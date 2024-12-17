;; Dispute Resolution Contract

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-invalid-dispute (err u102))

(define-map disputes
  { dispute-id: uint }
  {
    ride-id: uint,
    complainant: principal,
    respondent: principal,
    description: (string-utf8 500),
    status: (string-ascii 20),
    resolution: (optional (string-utf8 500))
  }
)

(define-data-var last-dispute-id uint u0)
(define-data-var arbitrator principal contract-owner)

(define-public (file-dispute (ride-id uint) (respondent principal) (description (string-utf8 500)))
  (let
    ((dispute-id (+ (var-get last-dispute-id) u1)))
    (map-set disputes
      { dispute-id: dispute-id }
      {
        ride-id: ride-id,
        complainant: tx-sender,
        respondent: respondent,
        description: description,
        status: "open",
        resolution: none
      })
    (var-set last-dispute-id dispute-id)
    (ok dispute-id)))

(define-public (resolve-dispute (dispute-id uint) (resolution (string-utf8 500)))
  (let
    ((dispute (unwrap! (map-get? disputes { dispute-id: dispute-id }) err-invalid-dispute)))
    (asserts! (is-eq tx-sender (var-get arbitrator)) err-not-authorized)
    (ok (map-set disputes
      { dispute-id: dispute-id }
      (merge dispute {
        status: "resolved",
        resolution: (some resolution)
      })))))

(define-public (set-arbitrator (new-arbitrator principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (var-set arbitrator new-arbitrator))))

(define-read-only (get-dispute (dispute-id uint))
  (ok (unwrap! (map-get? disputes { dispute-id: dispute-id }) err-invalid-dispute)))

