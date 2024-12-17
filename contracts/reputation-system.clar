;; Reputation System Contract

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-invalid-rating (err u102))

(define-map user-ratings
  { user: principal }
  {
    total-ratings: uint,
    total-score: uint
  }
)

(define-public (rate-user (user principal) (rating uint))
  (let
    ((current-ratings (default-to { total-ratings: u0, total-score: u0 } (map-get? user-ratings { user: user }))))
    (asserts! (and (>= rating u1) (<= rating u5)) err-invalid-rating)
    (ok (map-set user-ratings
      { user: user }
      {
        total-ratings: (+ (get total-ratings current-ratings) u1),
        total-score: (+ (get total-score current-ratings) rating)
      }))))

(define-read-only (get-user-rating (user principal))
  (let
    ((ratings (default-to { total-ratings: u0, total-score: u0 } (map-get? user-ratings { user: user }))))
    (if (is-eq (get total-ratings ratings) u0)
      (ok u0)
      (ok (/ (get total-score ratings) (get total-ratings ratings))))))

