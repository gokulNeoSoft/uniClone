pragma solidity >=0.7.0 <0.9.0;

import "./Pairs.sol";
import "./Factory.sol";
import "../helpers/Math.sol";
import "../helpers/Helper.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";



contract Router {
    address factoryAddress;
    constructor (address _factoryAddress){
        factoryAddress = _factoryAddress;
    }

    function decimalConvert (uint amount) internal pure returns (uint res){
        res = amount * (10 ** 18);
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) external  returns (uint amountA, uint amountB) {
        if (Factory(factoryAddress).getPair(tokenA, tokenB) == address(0)) {
            Factory(factoryAddress).createPairs(tokenA, tokenB);
        }
        address pairAddress = Factory(factoryAddress).getPair(tokenA, tokenB);
        (amountA, amountB) = Pairs(pairAddress)._addLiquidity(decimalConvert(amountADesired),decimalConvert(amountBDesired),decimalConvert(amountAMin),decimalConvert(amountBMin));
        uint userBalOfTokenA =  ERC20(tokenA).balanceOf(msg.sender);
        uint userBalOfTokenB =  ERC20(tokenB).balanceOf(msg.sender);
        require(userBalOfTokenA>amountA,"INSUFFICIENT BAL OF TOKEN A");
        require(userBalOfTokenB>amountB,"INSUFFICIENT BAL OF TOKEN B");
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pairAddress, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pairAddress, amountB);
        uint liquidity = Math.sqrt(amountA*amountB);
        Pairs(pairAddress).mint(msg.sender,liquidity);
        Pairs(pairAddress)._sync();

    }

    function _removeLiquidity(
        address tokenA,
        address tokenB
    ) external returns(uint amountA, uint amountB){
        address pairAddress = Factory(factoryAddress).getPair(tokenA, tokenB);
        (amountA, amountB) = Pairs(pairAddress)._removeLiquidity(msg.sender);
        require(amountA > 0 && amountB > 0, 'INSUFFICIENT_LIQUIDITY_BURNED');
        
    }


    function _swapExactTokensAtoB(
        address tokenA,
        address tokenB,
        uint exactAmountA
    ) external returns (uint amountA , uint amountB){
        address pairAddress = Factory(factoryAddress).getPair(tokenA, tokenB);
        exactAmountA = decimalConvert(exactAmountA);
        uint fee = calculateFeeAmount(exactAmountA);
        amountA = exactAmountA - fee;
        amountB = Pairs(pairAddress).getBamountOut(amountA);
        uint userBalOfTokenA =  ERC20(tokenA).balanceOf(msg.sender);
        require(userBalOfTokenA>amountA,"INSUFFICIENT BAL OF TOKEN A");
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pairAddress, fee);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pairAddress, amountA);
        Pairs(pairAddress).TransferBAmount(msg.sender,amountB);
        Pairs(pairAddress)._sync();
    }

    function _swapExactTokensBtoA(
        address tokenA,
        address tokenB,
        uint exactAmountB
    ) external returns (uint amountA , uint amountB){
        address pairAddress = Factory(factoryAddress).getPair(tokenA, tokenB);
        exactAmountB = decimalConvert(exactAmountB);
        uint fee = calculateFeeAmount(exactAmountB);
        amountB = exactAmountB - fee;
        amountA = Pairs(pairAddress).getAamountOut(amountB);
        uint userBalOfTokenB =  ERC20(tokenB).balanceOf(msg.sender);
        require(userBalOfTokenB>amountB,"INSUFFICIENT BAL OF TOKEN A");
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pairAddress, fee);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pairAddress, amountB);
        Pairs(pairAddress).TransferAAmount(msg.sender,amountA);
        Pairs(pairAddress)._sync();
    }

    function getReserve(
        address tokenA,
        address tokenB
    )external view returns (uint amountA , uint amountB){
        address pairAddress = Factory(factoryAddress).getPair(tokenA, tokenB);
        (amountA , amountB) =  Pairs(pairAddress).getReserves();
    }

    function calculateFeeAmount(
        uint amt
    ) internal view returns (uint fee){
        fee = amt*3/1000;
    }   
}