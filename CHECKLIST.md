# Checklist

_Feel free to submit a PR with anything else you can think of!_

## Contracts

- [x] Port pote.eth's transient loan concept to Huff.
  - [x] Add initial tests for expected behavior.
- [x] Add tstore/tload opcodes to huff-rs.
- [ ] Challenge
  - [x] Add external logic allows for overwriting an arbitrary transient storage slot via a TBD exploit.
    - [ ] Mark's idea:
      - [~] Implement way for the flash loan contract to delegatecall an external contract. The delegatecall should have
        exactly enough gas to perform 2 push ops and a tstore. This will allow the adversary to overwrite transient storage slot `1`,
        which contains the borrow array length. By setting this to zero, the adversary can skip the debt collection process and keep
        their flashloaned tokens. Afterwards, they will submit these tokens back to the `TransientLoan` contract to be included in
        the mainnet reward drop merkle tree.
        - [ ] Make this more difficult (pseudo-random storage slot?)
        - [ ] Add several honeypot functions to mislead participants.
        - [ ] Add opcode purity checker for the `delegatecall`'d contract- we don't want people to be able to overwrite
              persistent storage here. The gas limit for the delegate _should_ save us this effort, though.
      - [ ] Create mechanism for redeeming a reward NFT in exchange for any amount of mock tokens.
        - At the moment, the way this works is that the user will transfer stolen tokens back to the flash loaner
          contract in exchange for storing a `true` value in the `keccak256(msg.sender)` storage slot. We should be
          able to create a merkle tree for all EOAs that have a `true` value in their respective slots in order to create
          a reward NFT on mainnet.
        - [ ] Add event emission for easy indexing of solvers.
    - [ ] Determine a way to make the challenge EOA-specific. (i.e., use `keccak256(msg.sender, block.difficulty)` as a pseudo random seed.)
      - Note: If the challenge involves a psueudo-random, Leo and Hari from solc & [OptimizorClub](https://optimizor.club/) used an interesting
        method in their SQRT challenge that involved a [PurityChecker to limit several opcodes such as `EXTCODECOPY` and committing the solution
        64 blocks in advance.] Alternatively, we could go with [Kelvin's suggestion](https://twitter.com/kelvinfichter/status/1586879604148604929)
        of adding a way to invalidate solutions that exploit the pseudo-random value, which would take less time.
- [ ] Tests
  - [x] Local tests for exploit using persistent storage opcodes.
  - [ ] Find/replace `sstore`/`sload` with `tstore`/`tload` & test on Mark's testnet.
  - [ ] Wipe state of testnet before release / redeploy.

## UI

- [ ] Update [Whitenoise's CTF front-end](https://github.com/whitenois3/ctf-frontend) for the new CTF.

## Public

- [ ] Write short announcement post.
- [ ] Create Whitenois3 Twitter
