;; This is an example module you might write in your codebase. While the
;; ns and constants modules will be useful in your project, this file
;; is just an example and you'll want to delete it.
(namespace (read-msg "ns"))
(enforce-guard (keyset-ref-guard constants.ADMIN_KEYSET))

(module simple-staking GOVERNANCE
  @doc "A simple staking contract that allows users to stake KDA"

  (defcap GOVERNANCE ()
    @doc "Module governance. Only admin keyset can upgrade module."
    (enforce-guard (keyset-ref-guard constants.ADMIN_KEYSET)))

  (defcap ADMIN ()
    @doc "Only admin keyset can call admin functions"
    (enforce-guard (keyset-ref-guard constants.ADMIN_KEYSET)))

  (defcap OPS ()
    @doc "Only ops keyset can call ops functions"
    (enforce-guard (keyset-ref-guard constants.OPS_KEYSET)))

  (defcap INTERNAL ()
    @doc "Internal-only capability used to create a capability guard."
    true)

  (defcap STAKE (account:string amount:decimal)
    @doc "Capability for managing stake operations"
    @event
    (enforce-guard (at "guard" (coin.details account)))
    (enforce (> amount 0.0) "Stake amount must be positive"))

  (defcap UNSTAKE (account:string amount:decimal)
    @doc "Capability for managing unstake operations"
    @event
    (enforce-guard (at "guard" (coin.details account)))
    (enforce (> amount 0.0) "Unstake amount must be positive"))

  (defschema staker
    @doc "Information about a staker"
    balance:decimal  ; Amount of tokens staked
    guard:guard)    ; User's guard

  (defschema pool-info
    @doc "Information about the staking pool"
    total-staked:decimal  ; Total amount staked
    min-stake:decimal     ; Minimum stake amount
    paused:bool)         ; Emergency pause switch

  (deftable stakers:{staker})
  (deftable pool:{pool-info})

  ;; Admin functions
  (defun init-pool:string (min-stake:decimal)
    @doc "Initialize the staking pool"
    (with-capability (ADMIN)
      (enforce (> min-stake 0.0) "Minimum stake must be positive")

      (insert pool "pool"
        { "total-staked": 0.0
        , "min-stake": min-stake
        , "paused": false
        })))

  (defun set-paused:string (paused:bool)
    @doc "Pause or unpause staking operations"
    (with-capability (ADMIN)
      (update pool "pool"
        { "paused": paused })))

  ;; Ops functions
  (defun set-min-stake:string (new-min:decimal)
    @doc "Update minimum stake amount"
    (with-capability (OPS)
      (enforce (> new-min 0.0) "Minimum stake must be positive")
      (update pool "pool"
        { "min-stake": new-min })))

  ;; User functions
  (defun stake:string (account:string amount:decimal)
    @doc "Stake tokens"
    (enforce-pool-active)

    (with-capability (STAKE account amount)
      (with-read pool "pool" { "min-stake" := min-stake }
        (enforce (>= amount min-stake) "Stake amount below minimum"))

      (with-default-read stakers account
        { "balance": 0.0
        , "guard": (at "guard" (coin.details account)) }
        { "balance" := curr-balance
        , "guard" := guard }

        ; Transfer tokens to module
        (coin.transfer account constants.STAKING_ACCOUNT amount)

        ; Update staker's balance
        (write stakers account
          { "balance": (+ curr-balance amount)
          , "guard": guard })

        ; Update total staked
        (with-read pool "pool" { "total-staked" := total }
          (update pool "pool"
            { "total-staked": (+ total amount) })))))

  (defun unstake:string (account:string amount:decimal)
    @doc "Unstake tokens"
    (enforce-pool-active)

    (with-capability (UNSTAKE account amount)
      (with-read stakers account
        { "balance" := balance
        , "guard" := guard }

        ; Verify sufficient balance
        (enforce (<= amount balance) "Insufficient staked balance")

        ; Transfer tokens back to user
        (with-capability (INTERNAL)
          (install-capability (coin.TRANSFER constants.STAKING_ACCOUNT account amount))
          (coin.transfer constants.STAKING_ACCOUNT account amount))

        ; Update staker's balance
        (write stakers account
          { "balance": (- balance amount)
          , "guard": guard })

        ; Update total staked
        (with-read pool "pool" { "total-staked" := total }
          (update pool "pool"
            { "total-staked": (- total amount) })))))

  ;; Helper functions
  (defun enforce-pool-active:bool ()
    @doc "Enforce that the pool is not paused"
    (with-read pool "pool" { "paused" := paused }
      (enforce (not paused) "Pool is paused")))

  ;; Query functions
  (defun get-pool-info:object{pool-info} ()
    @doc "Get current pool information"
    (read pool "pool"))

  (defun get-staker-info:object{staker} (account:string)
    @doc "Get staker information"
    (read stakers account))
)

(create-table stakers)
(create-table pool)
