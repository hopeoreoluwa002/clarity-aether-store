;; AetherStore - Decentralized Marketplace

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u404))
(define-constant err-unauthorized (err u401))
(define-constant err-invalid-rating (err u100))
(define-constant err-insufficient-funds (err u101))
(define-constant err-invalid-price (err u102))
(define-constant err-invalid-status (err u103))

;; Data Variables
(define-data-var next-product-id uint u1)
(define-data-var next-order-id uint u1)

;; Data Maps
(define-map Products 
  uint 
  {
    seller: principal,
    name: (string-ascii 50),
    category: (string-ascii 20),
    price: uint,
    quantity: uint,
    active: bool
  }
)

(define-map Orders
  uint
  {
    product-id: uint,
    buyer: principal,
    seller: principal,
    price: uint,
    quantity: uint,
    status: (string-ascii 20)
  }
)

(define-map SellerRatings
  principal
  {
    total-ratings: uint,
    rating-sum: uint
  }
)

(define-map SellerBalances
  principal
  uint
)

;; Private Functions
(define-private (validate-price (price uint))
  (ok (> price u0))
)

(define-private (validate-status (status (string-ascii 20)))
  (or 
    (is-eq status "pending")
    (is-eq status "completed")
    (is-eq status "shipped")
    (is-eq status "cancelled")
  )
)

;; Public Functions
(define-public (list-product (name (string-ascii 50)) (category (string-ascii 20)) (price uint) (quantity uint))
  (let ((product-id (var-get next-product-id)))
    (try! (validate-price price))
    (map-set Products product-id {
      seller: tx-sender,
      name: name,
      category: category,
      price: price,
      quantity: quantity,
      active: true
    })
    (var-set next-product-id (+ product-id u1))
    (ok product-id)
  )
)

(define-public (delist-product (product-id uint))
  (let ((product (unwrap! (map-get? Products product-id) err-not-found)))
    (asserts! (is-eq tx-sender (get seller product)) err-unauthorized)
    (map-set Products product-id (merge product { active: false }))
    (ok true)
  )
)

(define-public (purchase-product (product-id uint) (quantity uint))
  (let (
    (product (unwrap! (map-get? Products product-id) err-not-found))
    (order-id (var-get next-order-id))
    (total-price (* (get price product) quantity))
  )
    (asserts! (>= (get quantity product) quantity) err-not-found)
    (asserts! (get active product) err-not-found)
    (try! (stx-transfer? total-price tx-sender (get seller product)))
    
    ;; Update seller balance
    (map-set SellerBalances (get seller product)
      (+ (default-to u0 (map-get? SellerBalances (get seller product))) total-price))
    
    (map-set Orders order-id {
      product-id: product-id,
      buyer: tx-sender,
      seller: (get seller product),
      price: (get price product),
      quantity: quantity,
      status: "pending"
    })
    (map-set Products product-id (merge product {
      quantity: (- (get quantity product) quantity)
    }))
    (var-set next-order-id (+ order-id u1))
    (ok order-id)
  )
)

(define-public (update-order-status (order-id uint) (new-status (string-ascii 20)))
  (let ((order (unwrap! (map-get? Orders order-id) err-not-found)))
    (asserts! (is-eq tx-sender (get seller order)) err-unauthorized)
    (asserts! (validate-status new-status) err-invalid-status)
    (map-set Orders order-id (merge order { status: new-status }))
    (ok true)
  )
)

(define-public (withdraw-funds)
  (let ((balance (default-to u0 (map-get? SellerBalances tx-sender))))
    (asserts! (> balance u0) err-insufficient-funds)
    (map-set SellerBalances tx-sender u0)
    (as-contract (stx-transfer? balance contract-owner tx-sender))
  )
)

(define-public (rate-seller (seller principal) (rating uint))
  (let (
    (current-rating (default-to {total-ratings: u0, rating-sum: u0} 
      (map-get? SellerRatings seller)))
  )
    (asserts! (<= rating u5) err-invalid-rating)
    (map-set SellerRatings seller {
      total-ratings: (+ (get total-ratings current-rating) u1),
      rating-sum: (+ (get rating-sum current-rating) rating)
    })
    (ok true)
  )
)

;; Read Only Functions
(define-read-only (get-product (product-id uint))
  (ok (map-get? Products product-id))
)

(define-read-only (get-order (order-id uint))
  (ok (map-get? Orders order-id))
)

(define-read-only (get-seller-rating (seller principal))
  (let ((rating (map-get? SellerRatings seller)))
    (if (is-some rating)
      (ok (/ (get rating-sum (unwrap-panic rating)) 
            (get total-ratings (unwrap-panic rating))))
      (ok u0)
    )
  )
)

(define-read-only (get-seller-balance (seller principal))
  (ok (default-to u0 (map-get? SellerBalances seller)))
)
