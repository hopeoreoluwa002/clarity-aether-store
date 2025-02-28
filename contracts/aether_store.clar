;; AetherStore - Decentralized Marketplace

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u404))
(define-constant err-unauthorized (err u401))
(define-constant err-invalid-rating (err u100))
(define-constant err-insufficient-funds (err u101))

;; Data Variables
(define-data-var next-product-id uint u1)
(define-data-var next-order-id uint u1)

;; Data Maps
(define-map Products 
  uint 
  {
    seller: principal,
    name: (string-ascii 50),
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

;; Public Functions
(define-public (list-product (name (string-ascii 50)) (price uint) (quantity uint))
  (let ((product-id (var-get next-product-id)))
    (map-set Products product-id {
      seller: tx-sender,
      name: name,
      price: price,
      quantity: quantity,
      active: true
    })
    (var-set next-product-id (+ product-id u1))
    (ok product-id)
  )
)

(define-public (purchase-product (product-id uint))
  (let (
    (product (unwrap! (map-get? Products product-id) err-not-found))
    (order-id (var-get next-order-id))
  )
    (asserts! (> (get quantity product) u0) err-not-found)
    (try! (stx-transfer? (get price product) tx-sender (get seller product)))
    (map-set Orders order-id {
      product-id: product-id,
      buyer: tx-sender,
      seller: (get seller product),
      price: (get price product),
      status: "completed"
    })
    (map-set Products product-id (merge product {
      quantity: (- (get quantity product) u1)
    }))
    (var-set next-order-id (+ order-id u1))
    (ok order-id)
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
