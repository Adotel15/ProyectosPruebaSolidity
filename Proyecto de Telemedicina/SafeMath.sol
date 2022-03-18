//SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 <0.7.0;
pragma experimental ABIEncoderV2;
import "./SafeMath.sol";

contract OperacionesBasicas {

    using SafeMath for uint256;

    constructor() internal{}

    // Funcion auxiliar para calcular el precio de los tokens ADP
    // Valor estándar 1 ether
    function CalcularPrecioToken(uint _numTokens) internal pure returns(uint)
    {
        return _numTokens * (1 ether);
    }

    // Funcion auxiliar para ver el balance de ethers
    function GetBalance() public view returns(uint)
    {
        return payable(address(this)).balance;
    }

    // Funcion auxiliar para convertir un entero sin signo en un string
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }



}