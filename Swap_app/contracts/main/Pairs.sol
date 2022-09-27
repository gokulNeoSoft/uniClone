pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Factory.sol";
import "../helpers/Math.sol";
import "../helpers/Helper.sol";

contract Pairs is ERC20{
    address private factoryAddress;
    address private routerAddress;
    address public token0;
    address public token1;
    uint private reserve0;   
    uint private reserve1;     
    ERC20 public ERC20Interface; 

    constructor() ERC20("lptoken", "LTK") {
        factoryAddress = msg.sender;
    }

    modifier onlyRouter {
      require(msg.sender == routerAddress);
      _;
    }

    function initialize(address _token0, address _token1,address _routerAddress)public {
        require(msg.sender==factoryAddress,"Only factory can call this function");
        token0 = _token0;
        token1 = _token1;
        routerAddress = _routerAddress;
    }

    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'INSUFFICIENT_LIQUIDITY');
        amountB = amountA*reserveB/ reserveA;
    }

    function getReserves() public view returns (uint _reserve0, uint _reserve1) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }

    function _update (uint amountA, uint amountB) internal  {
        reserve0 = reserve0 + amountA;
        reserve1 = reserve1 + amountB;
    }

    function mint(address to, uint256 amount) external  {
        uint decAmount = decimalConvert(amount);
        _mint(to, decAmount);

    }

    function decimalConvert (uint amount) internal view returns (uint res){
        res = amount * (10 ** uint256(decimals()));
    }




    function _addLiquidity(
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) external view onlyRouter returns (uint amountA, uint amountB) {       
        uint reserveA = reserve0;
        uint reserveB = reserve1;
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function _removeLiquidity(
        address account
    ) external  onlyRouter returns (uint amount0, uint amount1 ) {
        // (uint _reserve0, uint _reserve1) = getReserves();
        address _token0 = token0;                                
        address _token1 = token1;    
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf(account);
        uint _totalSupply = totalSupply(); 
        amount0 = liquidity*balance0 / _totalSupply; 
        amount1 = liquidity*balance1 / _totalSupply; 
        require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(account, liquidity);
        TransferHelper.safeTransfer(_token0, account, amount0);
        TransferHelper.safeTransfer(_token1, account, amount1);
        _sync();
        
    }

    function getBamountOut(
        uint amountA
    )external onlyRouter view returns(uint AmountOut){
        uint newA = reserve0+amountA;
        uint newB = reserve0* reserve1 / newA;
        AmountOut = reserve1-newB;
    } 

    function getAamountOut(
        uint amountB
    )external onlyRouter view returns(uint AmountOut){
        uint newB = reserve1+amountB;
        uint newA = reserve0* reserve1 / newB;
        AmountOut = reserve0-newA;
    } 

    function TransferBAmount( 
        address to , 
        uint amount
    ) external onlyRouter{
        TransferHelper.safeTransfer(token1, to,amount);
    }
    function TransferAAmount( 
        address to , 
        uint amount
    ) external onlyRouter{
        TransferHelper.safeTransfer(token0, to,amount);
    }

    function _sync() public  {
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        reserve0 = balance0;
        reserve1 = balance1;
    }
}