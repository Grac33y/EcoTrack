# EcoTrack

A blockchain-based environmental impact monitoring and carbon credit rewards system for sustainable practices.

## Overview

EcoTrack provides a transparent platform for monitoring environmental impact activities and distributing carbon credits based on verified sustainable practices. Organizations and individuals can track their eco-friendly actions and earn proportional rewards.

## Features

- **Impact Category Management**: Sustainability coordinators can approve environmental impact categories
- **Activity Tracking**: Record environmental impact activities with eco-points
- **Carbon Credit Distribution**: Automated carbon credit allocation based on impact contributions
- **Sustainability Certification**: Complete certification process with carbon credit rewards

## Smart Contract Functions

### Public Functions
- `establish-monitoring-system`: Initialize the environmental monitoring system
- `approve-impact-category`: Approve an impact category for monitoring
- `record-environmental-impact`: Record environmental impact activities
- `evaluate-carbon-credits`: Evaluate carbon credit distribution
- `complete-sustainability-certification`: Complete certification and claim credits

### Read-Only Functions
- `get-environmental-impact`: Get eco-points for a participant
- `get-impact-category`: Get impact category for a participant
- `get-total-eco-points`: Get total eco-points in system
- `is-category-approved`: Check if impact category is approved

## Getting Started

1. Deploy the contract to Stacks blockchain
2. Establish monitoring system with sustainability coordinator
3. Approve impact categories for tracking
4. Begin recording environmental impact activities

## License

MIT License
\`\`\`

```clarity file="project-3-healthvault/contracts/healthvault.clar"
;; HealthVault - Decentralized health data management and wellness incentive platform
(define-data-var health-administrator principal tx-sender)
(define-data-var total-wellness-tokens uint u0)
(define-data-var incentive-rate uint u100) ;; wellness incentives per health metric level
(define-data-var last-wellness-assessment uint u0)

(define-map health-metrics principal uint)
(define-map wellness-categories principal (string-utf8 64))
(define-map validated-categories (string-utf8 64) bool)

;; Error codes
(define-constant err-unauthorized-administrator (err u5100))
(define-constant err-administrator-already-set (err u5101))
(define-constant err-invalid-wellness-tokens (err u5102))
(define-constant err-no-wellness-incentives (err u5103))
(define-constant err-no-health-data (err u5104))
(define-constant err-invalid-wellness-category (err u5105))
(define-constant err-category-not-validated (err u5106))

;; Verify administrator authorization
(define-private (is-health-administrator (caller principal))
  (begin
    (asserts! (is-eq caller (var-get health-administrator)) err-unauthorized-administrator)
    (ok true)))

;; Initialize health data management system
(define-public (establish-health-system (administrator principal))
  (begin
    (asserts! (is-none (map-get? health-metrics administrator)) err-administrator-already-set)
    (var-set health-administrator administrator)
    (ok "HealthVault health data management system established")))

;; Validate wellness category for tracking
(define-public (validate-wellness-category (category (string-utf8 64)))
  (begin
    (try! (is-health-administrator tx-sender))
    (asserts! (> (len category) u0) err-invalid-wellness-category)
    (map-set validated-categories category true)
    (ok "Wellness category validated for tracking")))

;; Record health metrics and wellness data
(define-public (record-health-metrics (wellness-tokens uint) (wellness-category (string-utf8 64)))
  (begin
    (asserts! (> wellness-tokens u0) err-invalid-wellness-tokens)
    (asserts! (default-to false (map-get? validated-categories wellness-category)) err-category-not-validated)
    
    (let ((current-metrics (default-to u0 (map-get? health-metrics tx-sender))))
      (map-set health-metrics tx-sender (+ current-metrics wellness-tokens))
      (map-set wellness-categories tx-sender wellness-category)
      (var-set total-wellness-tokens (+ (var-get total-wellness-tokens) wellness-tokens))
      (ok (+ current-metrics wellness-tokens)))))

;; Assess wellness incentive distribution
(define-public (assess-wellness-incentives)
  (begin
    (try! (is-health-administrator tx-sender))
    (let ((current-assessment (+ (var-get last-wellness-assessment) u1))
          (total-tokens (var-get total-wellness-tokens)))
      (asserts! (> total-tokens (var-get last-wellness-assessment)) err-no-wellness-incentives)
      
      (let ((wellness-incentive-pool (* (var-get incentive-rate) total-tokens)))
        (var-set last-wellness-assessment current-assessment)
        (ok wellness-incentive-pool)))))

;; Complete health certification and claim wellness incentives
(define-public (complete-health-certification)
  (begin
    (let ((metric-tokens (default-to u0 (map-get? health-metrics tx-sender))))
      (asserts! (> metric-tokens u0) err-no-health-data)
      
      (let ((total-tokens (var-get total-wellness-tokens))
            (base-wellness-incentives (* (var-get incentive-rate) metric-tokens))
            (health-ratio (/ (* metric-tokens u100000) total-tokens)))
        
        (let ((final-wellness-incentives (/ (* health-ratio base-wellness-incentives) u100000)))
          (map-delete health-metrics tx-sender)
          (map-delete wellness-categories tx-sender)
          (var-set total-wellness-tokens (- (var-get total-wellness-tokens) metric-tokens))
          (ok (+ metric-tokens final-wellness-incentives)))))))

;; Read-only functions
(define-read-only (get-health-metrics (user principal))
  (default-to u0 (map-get? health-metrics user)))

(define-read-only (get-wellness-category (user principal))
  (map-get? wellness-categories user))

(define-read-only (get-total-wellness-tokens)
  (var-get total-wellness-tokens))

(define-read-only (is-category-validated (category (string-utf8 64)))
  (default-to false (map-get? validated-categories category)))
