//SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 <0.7.0;
pragma experimental ABIEncoderV2;
import "./ERC20.sol";

/*
    Proyecto de de prueba de un SmartContract que es una lotería, los que quieran jugar tiene que comprar el token LOT, y con él podrán comprar boletos,
    y luego el msg.sender puede llamar a la función para elegir a un ganador de manera aleatoria.
*/

contract Loteria
{
    // Instancia del Token LOT
    ERC20Basic private Token;

    // Direccion del propietario y del contrato
    address public owner;
    address public address_contract;

    // Num de tokens LOT
    uint public tokens_creados = 10000;

    // Constructor
    constructor() public{
        Token = new ERC20Basic(tokens_creados);
        owner = msg.sender;
        address_contract = address(this);
    }


    // ------------------------------- IMPLEMENTACION DEL TOKEN -------------------------------------

    // Eventos
    event compra_tokens(uint, address);

    // Función para establecer precio del token
    function PrecioToken(uint _numTokens) internal pure returns(uint){
        return _numTokens * (1 ether);
    }

    // Modifier del owner
    modifier SoloOwner(address _direccion){
        require (_direccion == owner, 'Solo el propietario puede aplicar esto');
        _;
    }

    // Funcion para ampliar el supply del token LOT
    function AumentarTokens(uint _NuevosTokens) public SoloOwner(msg.sender){
        Token.increaseTotalSupply(_NuevosTokens);
    }

    // Funcion para ver el balance
    function BalanceToken() public view returns(uint){
        return Token.balanceOf(address(this));
    }

    // Funcion para comprar tokens LOT
    function ComprarLOT(uint _numTokens) public payable{
        // Precio token
        uint Precio = PrecioToken(_numTokens);
        // Requerir que tenga los ethers
        require (msg.value >= Precio, ' No tienes suficientes ethers');
        // Tokens que sobran
        uint returnValue = msg.value - Precio;
        // Se los transferimos
        msg.sender.transfer(returnValue);
        // Que no compre mas tokens de los que tenemos
        uint Balance = BalanceToken();
        require (Balance >= _numTokens, 'No hay tantos tokens');
        // Trasnferencia de LOT al comprador
        Token.transfer(msg.sender, _numTokens);
        // Emitimos evento
        emit compra_tokens(_numTokens, msg.sender);
    }

    // Cuantos tokens LOT hay en el bote
    function Bote() public view returns(uint){
        return Token.balanceOf(owner);
    }

    // Cuantos Tokens LOT tienes
    function MisTokens() public view returns(uint){
        return Token.balanceOf(msg.sender);
    }

    // __________________________ IMPLEMENTACIÓN LOTERIA ________________________________

    // Precio de boleto en LOT, son 3 LOTS
    uint precioBoleto = 3;
    // Mapping para ver que boletos ha comprado alguien
    mapping (address => uint[]) idPersonas_boleto;
    // Mapping relacion inversa de boleto a ganador
    mapping(uint => address) ADN_boleto;
    // Numero aleatorio
    uint randNonce = 0;
    // Boletos generados
    uint[] Boleto_emitidos;
    // Eventos
    event ganador(address, uint);
    event comprado(address,uint);


    // Comprar boletos
    function ComprarBoletos(uint _numBoletos) public{
        // Precio total
        uint Precio = _numBoletos * precioBoleto;
        // Que tenga tokens suficiente
        require (MisTokens() >= Precio, 'Te faltan tokens');

        // Cojemos sus tokens y los ponemos en el bote, que es la address del owner
        Token.transferLOT(msg.sender, owner, Precio);

        // Le damos un boleto con número random
        for (uint i = 0; i < _numBoletos; ++i){

            // Para generar un numero aleatorio, usamos el hash (keccak256(abi.encodePacked("Cosas que sean diferentes cada vez"))
            // Y despues cojemos el uint que se genera que es super largo y cojemos los ultimos 4 digitos
            uint random = uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % 10000;
            randNonce++;

            // Le asignamos la persona al boleto
            idPersonas_boleto[msg.sender].push(random);

            // Asignamos el boleto al msg.sender
            ADN_boleto[random] = msg.sender;

            // Añadimos a la array total de boletos emitidos
            Boleto_emitidos.push(random);

            // Emitimos evento
            emit comprado(msg.sender, random);
        }
    }

    // Funcion que nos permite ver los boletos comprados
    function VerBoletos() public view returns(uint[] memory){
        return idPersonas_boleto[msg.sender];
    }

    // Fucnion para generar un ganador
    function GenerarGanador() public SoloOwner(msg.sender){
        // Que haya mas de 1 boleto
        require(Boleto_emitidos.length > 0, 'No hay suficientes boletos');

        uint longitud = Boleto_emitidos.length;

        // Generar posicion random que sea el ganador
        uint posicionWin =uint(uint(keccak256(abi.encodePacked(now))) % longitud);
        uint ganado = Boleto_emitidos[posicionWin];

        // Emitimos evento del ganador
        emit ganador(ADN_boleto[ganado], ganado);

        // Le damos los LOT al ganador
        address direccion_ganador = ADN_boleto[ganado];
        Token.transferLOT(owner, direccion_ganador, Bote());
    }

    // Funcion para cambiar LOT por ether
    function DevolverETH(uint _numTokens) public payable{

        // Dos requires que sea positvo el numero, y que tengas suficientes LOT de los que pides
        require(_numTokens > 0, 'Pon numero positivo');
        require(MisTokens() >= _numTokens, 'No tienes suficientes tokens');

        // Cojemos sus LOT y los pasamos al contrato
        Token.transferLOT(msg.sender, address(this), _numTokens);
        // Le damos el valor de LOT en ether a su wallet
        msg.sender.transfer(PrecioToken(_numTokens));
    }

}
