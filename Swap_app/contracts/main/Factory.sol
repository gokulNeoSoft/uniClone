// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import './Pairs.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract Factory is Ownable {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;
    Pairs private pairContract;
    address routerAddress;

    function createPairs(address _token0 , address _token1) external returns (Pairs) {
        require(_token0 != _token1, 'IDENTICAL_ADDRESSES');
        require(routerAddress != address(0), 'ROUTER ADDRESS NOT SET');
        require(getPair[_token0][_token1] == address(0), 'PAIR_EXISTS');
        pairContract = new Pairs();
        pairContract.initialize(_token0, _token1,routerAddress);
        getPair[_token0][_token1] = address(pairContract);
        getPair[_token1][_token0] = address(pairContract);
        allPairs.push(address(pairContract));
        return pairContract;
    }

    function setRouterAddress(address _routerAddress) external onlyOwner {
        routerAddress = _routerAddress;
    }

}

