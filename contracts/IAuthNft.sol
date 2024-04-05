// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// Main interface definition
interface IAuthNft {
    function check(address _user) external view returns (bool);

    function tokenOfOwnerByIndex(
        address _user,
        uint256 _index
    ) external view returns (uint256);

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;
}
