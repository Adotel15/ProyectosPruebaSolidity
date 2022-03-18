//SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
pragma experimental ABIEncoderV2;
import "./ERC20.sol";

contract Disney{

    // ---------------------------- DECLARACIONES INICIALES ----------------------------

    // Dirección del Propietario
    address public owner;

    // Token del parque Disney
    ERC20Basic private Token;

    // Constructor : Inicializa cuantos Tokens hay en total, y hace owner a la persona que despliega el contrato
    constructor() public{
        owner = msg.sender;
        Token = new ERC20Basic(15000);
    }

    // Estructura Cliente : Cuantos Tokens tiene, y en cuantas atracciones se ha montado
    struct Cliente{
        uint tokens_comprados;
        string[] atracciones_disfrutadas;
    }

    // Mapping para acceder a los datos de un cliente a través de su wallet
    mapping(address => Cliente) public Clientes;

    // ------------------------------- GESTION DE TOKENS -----------------------------------

    // Devuelve el precio del token DSY, estándar 1 DSY = 1 Ether
    function PrecioToken(uint _numTokens) public pure returns (uint){
        return _numTokens * (1 ether);
    }

    // Devuelve el balance que tiene el Contrato de tokens DSY
    function balancesOf() public view returns (uint){
        // Referncia a la función del ERC20Basic, this -> se refiere al contrato
        return Token.balanceOf(address(this));
    }
    
    // Función para comprar Tokens DSY con Ether
    function CompraTokens(uint _numTokens) public payable {

        // Establecemos el precio del token DSY, a través de la función PrecioToken()
        uint coste = PrecioToken(_numTokens);
        // Comprobamos que la cantidad que el cliente está dipositando no sea más pequeño que el coste
        require (msg.value >= coste, 'No tienes suficientes ether');
        // Vemos si ha sobrado algo que tengamos que devolverle
        uint returnValue = msg.value - coste;
        // Le devolvemos al msg.sender osea al Cliente, la cantidad de returnValue
        msg.sender.transfer(returnValue);
        // Vemos cuantos tokens DSY nos quedan en el contrato sin dar
        uint Balances = balancesOf();
        // Si se pasa de cantidad de la que tenemos disponible le insultamos un poco
        require (_numTokens <= Balances, 'Compra menos tokens mamahuevo');
        // Si no se pasa le damos el número de tokens DSY que ha comprado, ya hemos cogido sus ethers
        Token.transfer(msg.sender, _numTokens);
        // Almacenamos la información en la base de datos del contrato
        Clientes[msg.sender].tokens_comprados += _numTokens;

    }

    // Función para ver los tokens de un cliente
    function MisTokens() public view returns(uint){
        // return Clientes[msg.sender].tokens_comprados;
        return Token.balanceOf(msg.sender);
    }

    // Modifier para ver si eres el propietario
    modifier Unicamente(address _direccion){
        require (msg.sender == owner, 'No eres el propietario');
        _;
    }

    // Función para generar mas tokens DSY
    function GenerarTokens(uint _numTokens) public Unicamente(msg.sender){
        Token.increaseTotalSupply(_numTokens);
    }

    // ------------------------------- GESTION DE DISNEY -----------------------------------

    // Eventos
    event disfruta_atracciones(string);
    event nueva_atraccion(string, uint);
    event baja_atraccion(string);

    // Estructura de las atracciones
    struct Atraccion{
        string nombre_atraccion;
        uint precio_atraccion;
        bool estado_atraccion;
    }

    // Mapping para relacionar un string con una Atraccion
    mapping (string => Atraccion) public Atracciones;

    // Array con los nombres de las atracciones
    string[] nombre_atracciones;

    // Mapping para relacionar un cliente con su historial
    mapping(address => string[]) historialAtracciones;

    // Star Wars => 2 Tokens
    // Toy Story => 5 Tokens
    // Piratas del caribe => 8 Tokens

    // Funcion para crear una atraccion
    function NuevaAtraccion(string memory _nombre, uint precio) public Unicamente(msg.sender){

        // Añadimos al mapping y a la cadena de strings
        Atracciones[_nombre] = Atraccion(_nombre, precio, true);
        nombre_atracciones.push(_nombre);

        // Emitimos evento de nueva atraccion
        emit nueva_atraccion(_nombre, precio);

    }

    // Funcion para dar de baja una atraccion
    function DarBaja(string memory _nombre) public Unicamente(msg.sender){

        // Vemos si la atraccion existe
        bool presente = false;
        for (uint i = 0; i <  nombre_atracciones.length; ++i){
            if (keccak256(abi.encodePacked(nombre_atracciones[i])) == keccak256(abi.encodePacked(_nombre))) presente = true;
        }
        // Si no está paramos la ejecución
        require (presente, 'Esta atraccion no existe');
        // Cambiar estado de la atraccion
        Atracciones[_nombre].estado_atraccion = false;
        // Emitimos evento de baja
        emit baja_atraccion(_nombre);
    }

    // Funcion que devuelve que atracciones hay
    function atraccionesDisney() public view returns (string[] memory){
        return nombre_atracciones;
    }

    // Funcion para subirse a una atraccion y hacer el pago
    function SubirseAtraccion(string memory _nombreAtraccion) public{
        // Precio de la atraccion
        uint precio = Atracciones[_nombreAtraccion].precio_atraccion;
        // Verifica el estado de la atraccion
        require (Atracciones[_nombreAtraccion].estado_atraccion, 'Esta atraccion no esta disponible');
        // Verificar que la persona tiene tokens para pagar
        // require (Clientes[msg.sender].tokens_comprados >= precio, 'No tienes saldo suficiente');
        require (MisTokens() >= precio, 'No tienes saldo suficiente');

        // Cliente paga la atraccion en DSY
        // Se ha creado una funcion axuliar en la implementacion del ERC20 para cobrar
        Token.transferDis(msg.sender, address(this), precio);

        // Añadir el historial
        historialAtracciones[msg.sender].push(_nombreAtraccion);
        // Emitimos el evento
        emit disfruta_atracciones(_nombreAtraccion);

    }

    // Función para ver el historial de un cliente
    function VerHistorial() public view returns(string[] memory){
        return historialAtracciones[msg.sender];
    }

    // Funcion para devolver los ethers al cliente
    function DevolucionTokens(uint _numTokens) public payable{
        // Ver que tiene lo que pide
        require (_numTokens > 0, 'Pon un numero que sea real');
        // EL usuario tiene que tener los tokens
        require (MisTokens() >= _numTokens, 'No tienes tantos ethers flipao');
        // Cogemos sus DSY
        Token.transferDis(msg.sender, address(this), _numTokens);
        // Devuelve los ethers
        msg.sender.transfer(PrecioToken(_numTokens));
    }
}
