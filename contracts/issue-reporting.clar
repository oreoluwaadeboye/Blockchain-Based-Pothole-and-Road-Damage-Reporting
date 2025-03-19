;; Issue Reporting Contract
;; Allows citizens to document road problems

(define-constant contract-owner tx-sender)

;; Error codes
(define-constant err-not-authorized u100)
(define-constant err-issue-not-found u101)
(define-constant err-invalid-status u102)

;; Status constants
(define-constant status-reported u1)
(define-constant status-assessed u2)
(define-constant status-scheduled u3)
(define-constant status-in-repair u4)
(define-constant status-completed u5)
(define-constant status-verified u6)

;; Data maps
(define-map issues
  { issue-id: uint }
  {
    location-lat: int,
    location-lng: int,
    description: (string-utf8 100),
    reporter: principal,
    report-time: uint,
    status: uint,
    image-url: (string-utf8 100)
  }
)

(define-data-var issue-counter uint u0)

;; Read-only functions
(define-read-only (get-issue (issue-id uint))
  (map-get? issues { issue-id: issue-id })
)

(define-read-only (get-issue-count)
  (var-get issue-counter)
)

;; Public functions
(define-public (report-issue
    (location-lat int)
    (location-lng int)
    (description (string-utf8 100))
    (image-url (string-utf8 100)))
  (let
    (
      (new-id (+ (var-get issue-counter) u1))
    )
    (var-set issue-counter new-id)
    (map-set issues
      { issue-id: new-id }
      {
        location-lat: location-lat,
        location-lng: location-lng,
        description: description,
        reporter: tx-sender,
        report-time: block-height,
        status: status-reported,
        image-url: image-url
      }
    )
    (ok new-id)
  )
)

(define-public (update-issue-status (issue-id uint) (new-status uint))
  (let
    (
      (issue (unwrap! (get-issue issue-id) (err err-issue-not-found)))
    )
    ;; Only contract owner or original reporter can update status
    (asserts! (or (is-eq tx-sender contract-owner) (is-eq tx-sender (get reporter issue))) (err err-not-authorized))

    ;; Validate status
    (asserts! (and (>= new-status status-reported) (<= new-status status-verified)) (err err-invalid-status))

    (map-set issues
      { issue-id: issue-id }
      (merge issue { status: new-status })
    )
    (ok true)
  )
)

(define-public (update-issue-description (issue-id uint) (new-description (string-utf8 100)))
  (let
    (
      (issue (unwrap! (get-issue issue-id) (err err-issue-not-found)))
    )
    ;; Only original reporter can update description
    (asserts! (is-eq tx-sender (get reporter issue)) (err err-not-authorized))

    (map-set issues
      { issue-id: issue-id }
      (merge issue { description: new-description })
    )
    (ok true)
  )
)

