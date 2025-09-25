;; EcoTrack - Environmental impact monitoring and carbon credit rewards platform
(define-data-var sustainability-coordinator principal tx-sender)
(define-data-var total-carbon-credits uint u0)
(define-data-var credit-multiplier uint u25) ;; credit multiplier per impact level
(define-data-var last-carbon-assessment uint u0)

(define-map environmental-impact principal uint)
(define-map impact-categories principal (string-utf8 64))
(define-map verified-categories (string-utf8 64) bool)

;; Error codes
(define-constant err-unauthorized-coordinator (err u3100))
(define-constant err-coordinator-already-assigned (err u3101))
(define-constant err-invalid-carbon-credits (err u3102))
(define-constant err-no-carbon-rewards (err u3103))
(define-constant err-no-environmental-impact (err u3104))
(define-constant err-invalid-impact-category (err u3105))
(define-constant err-category-not-verified (err u3106))

;; Verify coordinator authorization
(define-private (is-sustainability-coordinator (caller principal))
  (begin
    (asserts! (is-eq caller (var-get sustainability-coordinator)) err-unauthorized-coordinator)
    (ok true)))

;; Initialize environmental monitoring program
(define-public (establish-eco-program (coordinator principal))
  (begin
    (asserts! (is-none (map-get? environmental-impact coordinator)) err-coordinator-already-assigned)
    (var-set sustainability-coordinator coordinator)
    (ok "EcoTrack environmental monitoring program established")))

;; Verify impact category for tracking
(define-public (verify-impact-category (category (string-utf8 64)))
  (begin
    (try! (is-sustainability-coordinator tx-sender))
    (asserts! (> (len category) u0) err-invalid-impact-category)
    (map-set verified-categories category true)
    (ok "Impact category verified for environmental tracking")))

;; Record environmental impact progress
(define-public (record-environmental-impact (carbon-credits uint) (impact-category (string-utf8 64)))
  (begin
    (asserts! (> carbon-credits u0) err-invalid-carbon-credits)
    (asserts! (default-to false (map-get? verified-categories impact-category)) err-category-not-verified)
    
    (let ((current-impact (default-to u0 (map-get? environmental-impact tx-sender))))
      (map-set environmental-impact tx-sender (+ current-impact carbon-credits))
      (map-set impact-categories tx-sender impact-category)
      (var-set total-carbon-credits (+ (var-get total-carbon-credits) carbon-credits))
      (ok (+ current-impact carbon-credits)))))

;; Assess carbon credit rewards
(define-public (assess-carbon-rewards)
  (begin
    (try! (is-sustainability-coordinator tx-sender))
    (let ((current-assessment (+ (var-get last-carbon-assessment) u1))
          (total-credits (var-get total-carbon-credits)))
      (asserts! (> total-credits (var-get last-carbon-assessment)) err-no-carbon-rewards)
      
      (let ((carbon-reward-pool (* (var-get credit-multiplier) total-credits)))
        (var-set last-carbon-assessment current-assessment)
        (ok carbon-reward-pool)))))

;; Complete environmental certification and claim rewards
(define-public (complete-eco-certification)
  (begin
    (let ((impact-credits (default-to u0 (map-get? environmental-impact tx-sender))))
      (asserts! (> impact-credits u0) err-no-environmental-impact)
      
      (let ((total-credits (var-get total-carbon-credits))
            (base-carbon-rewards (* (var-get credit-multiplier) impact-credits))
            (impact-ratio (/ (* impact-credits u100000) total-credits)))
        
        (let ((final-carbon-rewards (/ (* impact-ratio base-carbon-rewards) u100000)))
          (map-delete environmental-impact tx-sender)
          (map-delete impact-categories tx-sender)
          (var-set total-carbon-credits (- (var-get total-carbon-credits) impact-credits))
          (ok (+ impact-credits final-carbon-rewards)))))))

;; Read-only functions
(define-read-only (get-environmental-impact (participant principal))
  (default-to u0 (map-get? environmental-impact participant)))

(define-read-only (get-impact-category (participant principal))
  (map-get? impact-categories participant))

(define-read-only (get-total-carbon-credits)
  (var-get total-carbon-credits))

(define-read-only (is-category-verified (category (string-utf8 64)))
  (default-to false (map-get? verified-categories category)))
