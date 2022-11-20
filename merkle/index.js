const { MerkleTree } = require('merkletreejs')
const { ethers } = require('ethers')

const CHALLENGE_CONTRACT_ADDR = '0x34950D5CB9A785262b01c795f9b986E9697767ec'
const ABI = '[{"constant":true,"inputs":[],"name":"solvers","outputs":[{"name":"","type":"address[]"}],"payable":false,"stateMutability":"view","type":"function"}]'

const provider = new ethers.providers.JsonRpcProvider('https://rpc.eip1153.com/')
const run = async () => {
  const challengeContract = new ethers.Contract(CHALLENGE_CONTRACT_ADDR, ABI, provider)
  const challengeSolvers = await challengeContract.callStatic.solvers()
  const leaves = challengeSolvers.map((solver, i) => {
    return ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(["address", "uint256"], [solver, i + 1])
    )
  })

  const tree = new MerkleTree(leaves, ethers.utils.keccak256)
  const root = tree.getRoot().toString('hex')

  console.log(`Solvers:\n${challengeSolvers.map((solver, i) => `${i + 1}) ${solver}`).join('\n')}`)
  console.log(`Root: ${root}`)

  // Verify that all leaves are in the tree
  console.log('\nVerifying proofs...')
  const allVerified = leaves.reduce((acc, leaf, i) => {
    const proof = tree.getProof(leaf)
    const verified = tree.verify(proof, leaf, root)
    console.log(`Solver #${i + 1}: ${verified ? 'PASS' : 'FAIL'}`)
    return acc && verified
  }, true)
  console.log(`Tree is ${allVerified ? 'VALID' : 'INVALID'}!`)
}

run()
