<img align="right" width="150" height="150" top="100" src="./assets/ctf2.png">

## Whitenoise CTF II • [![ci](https://github.com/whitenois3/ctf2/actions/workflows/test.yml/badge.svg)](https://github.com/whitenois3/ctf2/actions/workflows/test.yml) [![license](https://img.shields.io/badge/License-MIT-orange.svg?label=license)](https://opensource.org/licenses/MIT)

Whitenoise CTF II: Tempestuous Transience


#### The Challenge

**First, What is EIP-1153?**

[EIP-1153](https://eips.ethereum.org/EIPS/eip-1153) introduces what are called _transient storage opcodes_ (`TSTORE` and `TLOAD`), allowing variables to persist across call frames until the end of the given transaction.

This enables new callback patterns where variables can persist in a contract and efficiently store state without needing to use gas ineffecient `sstore` and `sload` storage opcodes.

For example, [pote.eth](https://hackmd.io/@7-EMZFyUQNeY0Ttk6APiXA) outlines a [Transient, Non-custodial Flashloan Pattern](https://hackmd.io/@7-EMZFyUQNeY0Ttk6APiXA/r1rHOZ8mo#) originally proposed by [@sendmoodz](https://twitter.com/sendmoodz).

```solidity
interface IStartCallback {
    /// @notice Called on the `msg.sender` to hand over control to them.
    /// Expectation is that msg.sender#start will borrow tokens using NonCustodialFlashLoans#borrow,
    /// then return them to the original user before control is handed back to #start.
    function start() external;
}

contract NonCustodialFlashLoans {

    struct Borrow {
        uint256 lenderStartingBalance;
        address lender;
        IERC20 token;
    }

    // The full list of borrows that have occured in the current transaction.
    Borrow[] public transient borrows;

    // The user borrowing. Borrower is able to call #borrow to release tokens.
    address public transient borrower;

    /// @notice Entry Point. Start borrowing from the users that have approved this contract.
    function startLoan() external noReentrant {
        // TSTORE it!
        borrower = msg.sender;

        /// Hand control to the caller so they can start borrowing tokens
        IStartCallback(msg.sender).start();

        // At this point `msg.sender` should have returned any tokens that
        // were borrowed to each lender. Check this and revert if not!
        for (uint256 i = 0; i < borrowedAmounts.length; i++) {
            Borrow transient borrow = borrows[i]; // TLOAD!
            require(
                borrow.token.balanceOf(borrow.lender) >= borrow.lenderStartingBalance,
                'You must pay back the person you borrowed from!'
            );
        }

        // No need to clear the transient variables `borrows` and `borrower`!
    }

    // Only callable by `borrower`. Used to borrow tokens.
    function borrow(
        address from,
        IERC20 token,
        uint256 amount,
        address to
    ) external {
        require(msg.sender == borrower, 'Must be called from within the IStartCallback#start');

        // TSTORE what has been borrowed
        borrows.push(Borrow({lenderStartingBalance: token.balanceOf(from), lender: from, token: token}));

        token.transferFrom(from, to, amount);
    }
}
```
_Source: [Transient, Non-custodial Flashloan Pattern](https://hackmd.io/@7-EMZFyUQNeY0Ttk6APiXA/r1rHOZ8mo#)_


Breaking this down, `NonCustodialFlashLoans` allows a contract that implements `IStartCallback` to flashborrow tokens from _any_ token holder that has approved `NonCustodialFlashLoans` to spend their tokens, without having to have `NonCustodialFlashLoans` custody assets. To initiate the flashloan, the borrower calls `startLoan` which sets the _transient_ `borrower` variable to `msg.sender`. It is important that this variable is transient as its value will persist _inside_ the contract even if any subsequent calls to _other_ functions inside `NonCustodialFlashLoans` access the `borrower` variable.

The `startLoan` function can then call the `start` callback function on the borrower. In the borrower's `start` callback, they can make any number of calls to other `NonCustodialFlashLoans` functions (besides `startLoan` since it is protected against re-entrancy) and the `borrower` value in `NonCustodialFlashLoans` will still be set to the original borrower (`msg.sender`).

Since storage on nodes never have to write the `borrower` to disk (or any other transient variable for that matter), gas is significantly less expensive than the equivalent storage opcodes (`sstore` and `sload`).

When the `borrow` function is called on `NonCustodialFlashLoans` (shown in the solidity snippet above), the transient `borrower` value is checked, which should be set to the original borrower (`msg.sender`) who called the `startLoan` function.

Then, the balance of the token is recorded in transient storage along with the respective lender and token.

Finally, `NonCustodialFlashLoans` transfers the tokens to the borrower.

Then, the call frame will bubble up back to the borrowers's `start()` callback function which can perform any number of calls, permitting that it returns the tokens back to the lender before the end of the transaction. This is checked once the `start` call frame finishes, and the execution resumes inside the `startLoan` function. All `Borrow` objects recorded to transient storage are checked in a for loop.

And if all balance checks hold, TADA - the non-custodial transient flashloans succeeds!

Now that we broke down the utility of EIP-1153 Transient Opcodes, as used in a non-custodial transient flashloan context, let's explore how this pattern can introduce the vulnerability exposed by our [Whitenois3 CTF II](https://github.com/whitenois3/ctf2).


**Breaking Down The Exploit**

Although the `NonCustodialFlashLoans` contract has not been audited at the time of writing, the logic appears sound, and the Whitenois3 CTF II challenge is not a bug in the `NonCustodialFlashLoans` contract itself, but rather a bug in a specific implementation.

To provide a ...

// TODO: go through an example of how a malicious exploit contract / borrower can exploit the transient flashloan pattern to steal tokens from interest-bearing tokens.



### Licensing

Whitenoise CTF II is licensed under the [MIT License](https://opensource.org/licenses/MIT), go crazy with it.

> **Warning**
>
> These contracts are **unaudited** and are not recommended for use in production.
>
> Although contracts have been rigorously reviewed, this is **experimental software** and is provided on an "as is" and "as available" basis.
> We **do not give any warranties** and **will not be liable for any loss** incurred through any use of this codebase.


### Credits

These contracts were inspired by or directly modified from many sources, primarily:

- [Moody's Transient Flashloan Contract](https://hackmd.io/@7-EMZFyUQNeY0Ttk6APiXA/r1rHOZ8mo#)
- [whitenoise-ctf](https://github.com/whitenois3/whitenoise-ctf)
- [huffmate](https://github.com/pentagonxyz/huffmate)
- [solmate](https://github.com/transmissions11/solmate)
