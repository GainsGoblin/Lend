// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface Router {
    function swap(
        address[] memory,
        uint,
        uint,
        address
    ) external;
}