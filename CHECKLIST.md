# Checklist

_Feel free to submit a PR with anything else you can think of!_

## Contracts

- [x] Port pote.eth's transient loan concept to Huff.
  - [x] Add initial tests for expected behavior.
  - [ ] Add in non-custodial element - see comments at the top of the file. (Depending on if we need it for the challenge we choose)
- [x] Add tstore/tload opcodes to huff-rs.
- [ ] Challenge
  - [ ] Add external logic allows for overwriting an arbitrary transient storage slot via a TBD exploit.
    - [ ] Determine a way to make the challenge EOA-specific. (i.e., use `keccak256(msg.sender, block.difficulty)` as a pseudo random seed.)
      - Note: If the challenge involves a psueudo-random, Leo and Hari from solc & [OptimizorClub](https://optimizor.club/) used an interesting
        method in their SQRT challenge that involved a [PurityChecker to limit several opcodes such as `EXTCODECOPY` and committing the solution
        64 blocks in advance.] Alternatively, we could go with [Kelvin's suggestion](https://twitter.com/kelvinfichter/status/1586879604148604929)
        of adding a way to invalidate solutions that exploit the pseudo-random value, which would take less time.
  - [ ] Add several honeypot functions to mislead participants.
- [ ] Tests
  - [ ] Local tests for exploit using persistent storage opcodes.
  - [ ] Find/replace `sstore`/`sload` with `tstore`/`tload` & test on Mark's testnet.
  - [ ] Wipe state of testnet before release / redeploy.

## UI

- [ ] Update [Whitenoise's CTF front-end](https://github.com/whitenois3/ctf-frontend) for the new CTF.

## Public

- [ ] Write short announcement post.
- [ ] Create Whitenois3 Twitter
