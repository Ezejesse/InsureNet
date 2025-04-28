;; InsureNet: Decentralized Insurance Contract
;; A peer-to-peer insurance protocol that allows users to join coverage pools,
;; contribute funds, file claims, and receive payouts based on predefined conditions.

;; ----- Constants -----
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-pool-not-found (err u101))
(define-constant err-insufficient-funds (err u102))
(define-constant err-claim-not-found (err u103))
(define-constant err-already-voted (err u104))
(define-constant err-invalid-amount (err u105))
(define-constant err-claim-expired (err u106))
(define-constant err-no-active-policy (err u107))

;; ----- Data Maps -----
;; Insurance Pools
(define-map insurance-pools
  uint
  {
    pool-name: (string-ascii 50),
    coverage-type: (string-ascii 30),
    total-staked: uint,
    premium-rate: uint,
    min-stake: uint,
    active: bool,
    created-at: uint,
    admin: principal
  }
)

;; User Policies
(define-map user-policies
  { user: principal, pool-id: uint }
  {
    premium-paid: uint,
    coverage-amount: uint,
    start-block: uint,
    end-block: uint,
    active: bool
  }
)

;; Insurance Claims
(define-map claims
  uint
  {
    claimer: principal,
    pool-id: uint,
    amount: uint,
    description: (string-ascii 200),
    evidence-hash: (buff 32),
    created-at: uint,
    expires-at: uint,
    status: (string-ascii 20), ;; "pending", "approved", "rejected"
    yes-votes: uint,
    no-votes: uint
  }
)

;; Claim Votes
(define-map claim-votes
  { claim-id: uint, voter: principal }
  bool ;; true for yes, false for no
)

;; ----- Variables -----
(define-data-var pool-id-nonce uint u0)
(define-data-var claim-id-nonce uint u0)
(define-data-var min-votes-required uint u3)
(define-data-var claim-duration uint u144) ;; ~1 day in blocks

;; ----- Read-Only Functions -----
(define-read-only (get-pool-info (pool-id uint))
  (map-get? insurance-pools pool-id)
)

(define-read-only (get-user-policy (user principal) (pool-id uint))
  (map-get? user-policies { user: user, pool-id: pool-id })
)

(define-read-only (get-claim-info (claim-id uint))
  (map-get? claims claim-id)
)

(define-read-only (has-voted (claim-id uint) (voter principal))
  (is-some (map-get? claim-votes { claim-id: claim-id, voter: voter }))
)

(define-read-only (check-active-policy (user principal) (pool-id uint))
  (match (map-get? user-policies { user: user, pool-id: pool-id })
    policy (and (get active policy) 
                (< block-height (get end-block policy)))
    false
  )
)

;; Helper function to calculate voting confidence factor
(define-read-only (get-voting-confidence-factor (claim-id uint))
  (let
    ((claim (unwrap! (map-get? claims claim-id) u0))
     (yes-votes (get yes-votes claim))
     (no-votes (get no-votes claim))
     (total-votes (+ yes-votes no-votes)))
    
    (if (< total-votes u3)
        u10 ;; Not enough votes yet
        (if (> (* yes-votes u2) total-votes)
            u0  ;; Strong approval
            (if (> (* no-votes u2) total-votes)
                u25 ;; Strong rejection
                u15))) ;; Mixed opinions
  )
)

;; Calculate fraud score based on various risk factors
(define-read-only (calculate-fraud-score (claim-id uint))
  (let
    ((claim (unwrap! (map-get? claims claim-id) u0))
     (policy (unwrap! (map-get? user-policies { user: (get claimer claim), pool-id: (get pool-id claim) }) u0))
     (policy-age (- block-height (get start-block policy)))
     (claim-ratio (/ (* (get amount claim) u100) (get coverage-amount policy)))
     (base-score u50)
     (policy-age-factor (if (< policy-age u1000) u15 u0))
     (amount-factor (if (> claim-ratio u80) u25 u0))
     (evidence-factor (if (is-eq (get evidence-hash claim) 0x0000000000000000000000000000000000000000000000000000000000000000) u25 u0))
     (voting-factor (get-voting-confidence-factor claim-id)))
    
    ;; Higher score = higher risk
    (+ base-score policy-age-factor amount-factor evidence-factor voting-factor)
  )
)

;; Process a claim if it has received enough votes
(define-public (process-claim-if-ready (claim-id uint))
  (let
    ((claim (unwrap! (map-get? claims claim-id) err-claim-not-found))
     (total-votes (+ (get yes-votes claim) (get no-votes claim))))
    
    (if (>= total-votes (var-get min-votes-required))
      (let
        ((result (> (get yes-votes claim) (get no-votes claim))))
        (if result
          (begin
            ;; Approve the claim and transfer funds
            (try! (as-contract (stx-transfer? (get amount claim) tx-sender (get claimer claim))))
            (map-set claims claim-id (merge claim { status: "approved" }))
            (ok true)
          )
          (begin
            ;; Reject the claim
            (map-set claims claim-id (merge claim { status: "rejected" }))
            (ok false)
          )
        )
      )
      (ok true) ;; Not enough votes yet
    )
  )
)

;; ----- Public Functions -----
;; Create a new insurance pool
(define-public (create-insurance-pool 
                (name (string-ascii 50)) 
                (coverage-type (string-ascii 30))
                (premium-rate uint)
                (min-stake uint))
  (let
    ((new-pool-id (+ (var-get pool-id-nonce) u1)))
    (asserts! (> min-stake u0) err-invalid-amount)
    (asserts! (> premium-rate u0) err-invalid-amount)
    
    (map-set insurance-pools new-pool-id
      {
        pool-name: name,
        coverage-type: coverage-type,
        total-staked: u0,
        premium-rate: premium-rate,
        min-stake: min-stake,
        active: true,
        created-at: block-height,
        admin: tx-sender
      }
    )
    (var-set pool-id-nonce new-pool-id)
    (ok new-pool-id)
  )
)

;; Join an insurance pool as a provider (stake funds)
(define-public (stake-in-pool (pool-id uint) (amount uint))
  (let
    ((pool (unwrap! (map-get? insurance-pools pool-id) err-pool-not-found)))
    
    (asserts! (get active pool) err-pool-not-found)
    (asserts! (>= amount (get min-stake pool)) err-insufficient-funds)
    
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    (map-set insurance-pools pool-id
      (merge pool { total-staked: (+ (get total-staked pool) amount) })
    )
    (ok true)
  )
)

;; Purchase insurance coverage
(define-public (purchase-coverage (pool-id uint) (coverage-amount uint) (duration uint))
  (let
    ((pool (unwrap! (map-get? insurance-pools pool-id) err-pool-not-found))
     (premium-to-pay (/ (* coverage-amount (get premium-rate pool)) u10000)))
    
    (asserts! (get active pool) err-pool-not-found)
    (asserts! (> coverage-amount u0) err-invalid-amount)
    (asserts! (> duration u0) err-invalid-amount)
    
    (try! (stx-transfer? premium-to-pay tx-sender (as-contract tx-sender)))
    
    (map-set user-policies 
      { user: tx-sender, pool-id: pool-id }
      {
        premium-paid: premium-to-pay,
        coverage-amount: coverage-amount,
        start-block: block-height,
        end-block: (+ block-height duration),
        active: true
      }
    )
    (ok true)
  )
)

;; File an insurance claim
(define-public (file-claim (pool-id uint) (amount uint) (description (string-ascii 200)) (evidence-hash (buff 32)))
  (let
    ((new-claim-id (+ (var-get claim-id-nonce) u1))
     (policy (unwrap! (map-get? user-policies { user: tx-sender, pool-id: pool-id }) err-no-active-policy)))
    
    (asserts! (check-active-policy tx-sender pool-id) err-no-active-policy)
    (asserts! (<= amount (get coverage-amount policy)) err-invalid-amount)
    
    (map-set claims new-claim-id
      {
        claimer: tx-sender,
        pool-id: pool-id,
        amount: amount,
        description: description,
        evidence-hash: evidence-hash,
        created-at: block-height,
        expires-at: (+ block-height (var-get claim-duration)),
        status: "pending",
        yes-votes: u0,
        no-votes: u0
      }
    )
    (var-set claim-id-nonce new-claim-id)
    (ok new-claim-id)
  )
)

;; Vote on an insurance claim (stakers can vote)
(define-public (vote-on-claim (claim-id uint) (vote bool))
  (let
    ((claim (unwrap! (map-get? claims claim-id) err-claim-not-found))
     (pool (unwrap! (map-get? insurance-pools (get pool-id claim)) err-pool-not-found)))
    
    (asserts! (< block-height (get expires-at claim)) err-claim-expired)
    (asserts! (not (has-voted claim-id tx-sender)) err-already-voted)
    
    ;; Record the vote
    (map-set claim-votes { claim-id: claim-id, voter: tx-sender } vote)
    
    ;; Update the claim's vote counts
    (if vote
      (map-set claims claim-id (merge claim { yes-votes: (+ (get yes-votes claim) u1) }))
      (map-set claims claim-id (merge claim { no-votes: (+ (get no-votes claim) u1) }))
    )
    
    ;; Check if enough votes to finalize
    (process-claim-if-ready claim-id)
  )
)

;; Smart claim processing system with automated risk assessment
(define-public (process-claim-with-risk-assessment (claim-id uint))
  (let
    ((claim (unwrap! (map-get? claims claim-id) err-claim-not-found))
     (pool-id (get pool-id claim))
     (pool (unwrap! (map-get? insurance-pools pool-id) err-pool-not-found))
     (user-policy (unwrap! (map-get? user-policies { user: (get claimer claim), pool-id: pool-id}) err-no-active-policy))
     (total-votes (+ (get yes-votes claim) (get no-votes claim)))
     (fraud-score (calculate-fraud-score claim-id))
     (risk-threshold u65))
    
    ;; Check if claim is still pending
    (asserts! (is-eq (get status claim) "pending") (err u108))
    
    ;; Check if claim has expired or received enough votes
    (asserts! (or
               (>= block-height (get expires-at claim))
               (>= total-votes (var-get min-votes-required)))
              (err u109))
    
    ;; Automated risk assessment
    (if (< fraud-score risk-threshold)
        ;; Low risk - process automatically if yes votes > no votes
        (if (> (get yes-votes claim) (get no-votes claim))
            (begin
              ;; Approve claim and transfer funds
              (try! (as-contract (stx-transfer? (get amount claim) tx-sender (get claimer claim))))
              (map-set claims claim-id (merge claim { status: "approved" }))
              (map-set user-policies 
                       { user: (get claimer claim), pool-id: pool-id }
                       (merge user-policy { active: false }))
              (ok true))
            ;; Rejected by votes
            (begin
              (map-set claims claim-id (merge claim { status: "rejected" }))
              (ok false)))
        ;; High risk - escalate to manual review
        (begin
          (map-set claims claim-id (merge claim { status: "manual-review" }))
          (ok false))
    )
  )
)

