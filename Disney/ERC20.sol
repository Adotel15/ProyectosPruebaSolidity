//SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
pragma experimental ABIEncoderV2;
import "./SafeMath.sol";

// Adri 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
// Flynn 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
// Manu 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
// Sergi 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB

interface ERC20
{
    //Devuelve la cantidad de tokens total
    function totalSupply() external view returns(uint256);

    //Cantidad de tokens de una wallet
    function balanceOf(address account) external view returns(uint256);

    //Numero de tokens que el spender puede gastar en nombre del propietario
    function allowance(address owner, address spender) external view returns(uint256);

    //Devuelve bool si se puede enviar esa cantidad al receptor
    function transfer(address recipient, uint256 amount) external returns(bool);

    //Funcion auxiliar para cobrar tokens Disney
    function transferDis(address _cliente, address recipient, uint256 amount) external returns(bool);

    //Devuelve bool con el resultado de la transacción
    function approve(address spender, uint256 amount) external returns(bool);

    //Devuelve bool de si se ha llevado acabo la transacción de allowance()
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);



    //Evento cuando haya una transacción
    event Transfer(address indexed from, address indexed to, uint256 value);

    //Evento cuando se haya aprobado un allowance de que una direccion puede gastar tokens de un propietario
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


//Implementacion de las ERC20
contract ERC20Basic is ERC20
{

    string public constant name = "DisneyToken";
    string public constant symbol = "DSY";
    uint8 public constant decimals = 2;

    mapping(address => uint) balances;

    mapping(address => mapping(address => uint)) allowed;

    uint256 totalSupply_;

    constructor(uint256 _initialSupply) public{
        totalSupply_ = _initialSupply;
        balances[msg.sender] = totalSupply_;
    }

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed owner, address indexed spender, uint256 tokens);

    using SafeMath for uint256;

    function totalSupply() public override view returns(uint256){
        return totalSupply_;
    }

    function increaseTotalSupply(uint _newTokensAmount) public{
        totalSupply_ += _newTokensAmount;
        balances[msg.sender] += _newTokensAmount;
    }

    function balanceOf(address _tokenOwner) public override view returns(uint256){
        return balances[_tokenOwner];
    }

    function allowance(address owner, address delegate) public override view returns(uint256){
        return allowed[owner][delegate];
    }

    function transfer(address recipient, uint256 _numTokens) public override returns(bool){
        require(_numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_numTokens);
        balances[recipient] = balances[recipient].add(_numTokens);

        emit Transfer(msg.sender, recipient, _numTokens);
        return true;
    }

    function transferDis(address _cliente, address recipient, uint256 _numTokens) public override returns(bool){
        require(_numTokens <= balances[_cliente]);
        balances[_cliente] = balances[_cliente].sub(_numTokens);
        balances[recipient] = balances[recipient].add(_numTokens);

        emit Transfer(_cliente, recipient, _numTokens);
        return true;
    }

    function approve(address _delegate, uint256 _numTokens) public override returns(bool){
        require(_numTokens <= balances[msg.sender]);
        allowed[msg.sender][_delegate] = _numTokens;

        emit Approval(msg.sender, _delegate, _numTokens);
        return true;

    }

    function transferFrom(address owner, address buyer, uint256 _numTokens) public override returns(bool){
        require(_numTokens <= balances[owner]);
        require(_numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(_numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(_numTokens);
        balances[buyer] = balances[buyer].add(_numTokens);

        emit Transfer(owner, buyer, _numTokens);
        return true;
    }

}