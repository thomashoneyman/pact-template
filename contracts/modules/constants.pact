;; This file defines some constant values for our protocol use, within
;; the principal namespace defined via ns.pact.
(namespace (read-msg "ns"))

(module constants GOVERNANCE
  (defcap GOVERNANCE:bool () (enforce-guard ADMIN_GUARD))

  (defconst ADMIN_KEYSET (+ (read-msg "ns") ".admin-keyset"))
  (defconst ADMIN_GUARD (keyset-ref-guard ADMIN_KEYSET))

  (defconst OPS_KEYSET (+ (read-msg "ns") ".ops-keyset"))
  (defconst OPS_GUARD (keyset-ref-guard OPS_KEYSET))

  (defconst STAKING_ACCOUNT (+ (read-msg "ns") ".staking-pool"))
)

(enforce-guard ADMIN_GUARD)
