;; Ride Management Contract

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-invalid-ride (err u102))
(define-constant err-ride-not-open (err u103))

(define-map rides
  { ride-id: uint }
  {
    passenger: principal,
    driver: (optional principal),
    pickup: (string-utf8 100),
    dropoff: (string-utf8 100),
    price: uint,
    status: (string-ascii 20)
  }
)

(define-data-var last-ride-id uint u0)

(define-public (request-ride (pickup (string-utf8 100)) (dropoff (string-utf8 100)) (price uint))
  (let
    ((ride-id (+ (var-get last-ride-id) u1)))
    (map-set rides
      { ride-id: ride-id }
      {
        passenger: tx-sender,
        driver: none,
        pickup: pickup,
        dropoff: dropoff,
        price: price,
        status: "open"
      })
    (var-set last-ride-id ride-id)
    (ok ride-id)))

(define-public (accept-ride (ride-id uint))
  (let
    ((ride (unwrap! (map-get? rides { ride-id: ride-id }) err-invalid-ride)))
    (asserts! (is-eq (get status ride) "open") err-ride-not-open)
    (ok (map-set rides
      { ride-id: ride-id }
      (merge ride {
        driver: (some tx-sender),
        status: "accepted"
      })))))

(define-public (complete-ride (ride-id uint))
  (let
    ((ride (unwrap! (map-get? rides { ride-id: ride-id }) err-invalid-ride)))
    (asserts! (is-eq (some tx-sender) (get driver ride)) err-not-authorized)
    (asserts! (is-eq (get status ride) "accepted") err-ride-not-open)
    (try! (stx-transfer? (get price ride) (get passenger ride) tx-sender))
    (ok (map-set rides
      { ride-id: ride-id }
      (merge ride { status: "completed" })))))

(define-read-only (get-ride (ride-id uint))
  (ok (unwrap! (map-get? rides { ride-id: ride-id }) err-invalid-ride)))

