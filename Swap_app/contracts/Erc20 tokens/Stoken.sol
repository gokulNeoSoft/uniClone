pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Stoken is ERC20, Ownable {
    constructor() ERC20("Ctoken", "CTK") {
        _mint(msg.sender, 50000000000000000000);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        uint decAmount = decimalConvert(amount);
        _mint(to, decAmount);

    }

    function approveSpender(address _spender, uint amount) public {
        uint decAmount = decimalConvert(amount);
        _approve(msg.sender,_spender, decAmount);    
    }

    function decimalConvert (uint amount) internal view returns (uint res){
        res = amount * (10 ** uint256(decimals()));
    }
    
}