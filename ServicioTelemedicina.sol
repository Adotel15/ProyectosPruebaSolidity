//SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 <0.7.0;
pragma experimental ABIEncoderV2;
import "./ERC20.sol";
import "./OperacionesBasicas.sol";


// ----------------- CONTRATO PRINCIPAL -----------------------

contract InsuranceFactory is OperacionesBasicas {

    // Token IF con el que se harán los pagos 1 IF = 1 Ether
    ERC20Basic private Token;

    // ----- Direcciones -------
    // Direccion del SmartContract
    address ContratoInsurance;

    // Direccion del propietario, donde va el dinero
    address payable public Aseguradora;

     // Constructor se inicializa el Token IF, y las direcciones del contrato y del propietario
    constructor() public{

        Token = new ERC20Basic(100);
        ContratoInsurance = address(this);
        Aseguradora = msg.sender;

    }

    // -------- STRUCTS --------
    
    // Toda la informacion del cliente
    struct Cliente{
        address direccionCliente;
        bool autorizadoCliente;
        address ContratoCliente;
    }

    // Toda la infromacion del servicio en cuestión
    struct Servicio{
        string nombreServicio;
        uint precioServicio;
        bool operativo;
    }

    // Informacion de los laboratorios
    struct Lab{
        address direccionContrato;
        bool operativo;
    }

    // ---------- Mappings ----------
    // Para relacionar address y string a los Structs

    mapping (address => Cliente) public MapCliente;
    mapping (string => Servicio) public MapServicios;
    mapping (address => Lab) public MapLab;

    // ---------- Arrays ------------
    // Para guardars los servicios(string), laboratorios(address), y clientes(address)

    string[] Servicios;
    address[] private DireccionesLaboratorios; // De las wallets no del contrato
    address[] DireccionesAseguradas;

    // --------------- FUNCIONES AUXILIARES ----------------------

    // Funcion auxiliar para los modifiers para no tener que hacer el require cada vez para comprobar si es valido
    function FuncionUnicamenteAsegurado(address _direccionAsegurado) public view {
        require(MapCliente[_direccionAsegurado].autorizadoCliente == true , "No estas autorizado");
    }

    // Funcion auxiliar que devuelve un bool, de si un servicio esta operativo o no
    function ServicioEstado(string memory _nombre) public view returns(bool){
        return MapServicios[_nombre].operativo;
    }

    // Funcion auxliar para ver cuantos tokens tiene el smart Contrato de Insurance
    function BalanceOf() public view returns(uint){
        return Token.balanceOf(ContratoInsurance);
    }

    

    // --------- Modifiers -----------

    // Solo personas autorizadas, que se hayan registrado y que esten autorizadas
    modifier UnicamenteAsegurado(address _direccionAsegurado){
        FuncionUnicamenteAsegurado(_direccionAsegurado);
        _;
    }

    // Solo aseguradora, osea el propietario
    modifier UnicamenteAseguradora(address _direccionAseguradora){
        require (Aseguradora == _direccionAseguradora, "No tienes permitido el acceso");
        _;
    }

    // Comprobar que nadie hace peticiones en nombre de otro, y o es el propietario
    modifier AseguradoOAseguradora(address _Asegurado, address _Entrante){
        require (Aseguradora == _Entrante || ( MapCliente[_Asegurado].autorizadoCliente == true && _Asegurado == _Entrante), 
            "No tienes permisos para entrar");
        _;
    }

    // ----------- EVENTOS -----------

    // Compra de Tokens y cuantos
    event EventTokensComprado(uint);
    // Servicio proporcionado, a que address, y que precio
    event EventServicioProporcionado(address, string, uint);
    // Lab creado, la direccion del propietario y el contrato
    event EventLaboratorioCreado(address, address);
    // Asegurado(Cliente) que se crea, su direccion y su contrato
    event EventClienteCreado(address, address);
    // Cliente se da de baja
    event EventBajaCliente(address);
    // Nuevo servicio
    event EventNuevoServicio(string, uint);
    // Baja servicio
    event EventBajaServicio(string);

    // --------- FUNCIONES -----------

    // Funcion para crear un laboratorio
    function creacionLab() public{

        // Añadimos la direccion del creador del lab a la array
        DireccionesLaboratorios.push(msg.sender);
        // Creamos el contrato y guardamos su direccion en el mapping
        address LabCreadoContrato = address(new Laboratorio(msg.sender, ContratoInsurance));
        MapLab[msg.sender] = Lab(LabCreadoContrato, true);

        // Emitimos el evento      
        emit EventLaboratorioCreado(msg.sender, LabCreadoContrato);
    }

    // Funcion para crear un cliente
    function creacionCliente() public{

        // Añadimos la wallet del cliente a la array
        DireccionesAseguradas.push(msg.sender);
        // Creamos el contrato y lo añadimos al mapping
        address ClienteCreado = address(new InsuranceHealthRecord(msg.sender, Token, ContratoInsurance, Aseguradora));
        MapCliente[msg.sender] = Cliente(msg.sender, true, ClienteCreado);

        // Emitimos evento
        EventClienteCreado(msg.sender, ClienteCreado);
    }

    // Devuelve todas las direcciones de los Laboratorios, solo el propietario
    function Laboratorios() public view UnicamenteAseguradora(msg.sender) returns(address[] memory){
        return DireccionesLaboratorios;
    }

    // Devuelve todos los clientes, solo el propietario
    function Asegurados() public view UnicamenteAseguradora(msg.sender) returns(address[] memory){
        return DireccionesAseguradas;
    }

    // Devuelve todos los servicios que ha contratado un cliente
    function ConsultarHistorialCliente(address _direccionAsegurado, address _direccionConsultor) public view AseguradoOAseguradora(_direccionAsegurado, _direccionConsultor) returns (string memory) {
        
        // Aquí es donde guardaremos los nombres de los servicios que ha contratado
        string memory historial = "";
        // Direccion del contrato del cliente sacado de el mapping
        address direccionContratoCliente = MapCliente[_direccionAsegurado].ContratoCliente;
        
        // Bucle que reccore toda la array de servicios
        // Por cada nombre de servicio, comprobamos que este operativo, tanto en el contrato principal como en el del cliente
        // Si es así, cogemos los datos de la struct del cliente ServicioSolicitado a traves de la funcion Historial cliente a la que le pasamos el nombre del servicio
        // Y los añadimos al historial, usando abi.EncodePacked y convirtiendo todo en string
        for (uint i = 0; i < Servicios.length; ++i)
        {
            if (MapServicios[Servicios[i]].operativo &&
            InsuranceHealthRecord(direccionContratoCliente).ServicioEstadoCliente(Servicios[i])
            ){
                (string memory nombreServicio, uint256 precioServicio) = InsuranceHealthRecord(direccionContratoCliente).HistorialCliente(Servicios[i]);
                historial = string(abi.encodePacked(historial, "(", nombreServicio, ", ", uint2str(precioServicio), ") "));
            }
        }

        return historial;
    }

    // Funcion para dar de baja un cliente, sencillamente ponemos en false su autorizacion
    function DarBajaCliente(address _cliente) public UnicamenteAseguradora(msg.sender) {
        MapCliente[_cliente].autorizadoCliente = false;
        // darBaja destruye el contrato del cliente
        InsuranceHealthRecord(MapCliente[_cliente].ContratoCliente).darBaja;
        emit EventBajaCliente(_cliente);
    }
    
    /*
    function darBajaCliente(address _direccionAsegurado) public UnicamenteAseguradora(msg.sender) returns (string memory){
            // La autorizacion del aseguradora se anula
            MapCliente[_direccionAsegurado].autorizadoCliente = false;
            // Se llama al metodo self destruct del cliente y se da de baja el cliente relacionado a la dirección entrada para parametro
            InsuranceHealthRecord(MapCliente[_direccionAsegurado].ContratoCliente).darBaja;
            // Emision del evento
            emit EventBajaCliente(_direccionAsegurado);
        }
        */

    // Funcion para dar de alta un nuevo servicio, y lo añadimos al mapping y a la array
    function NuevoServicio(string memory _nombre, uint _precioServicio) public UnicamenteAseguradora(msg.sender){
        MapServicios[_nombre] = Servicio(_nombre, _precioServicio, true);
        Servicios.push(_nombre);
        emit EventNuevoServicio(_nombre, _precioServicio);
    }

    // Funcion para dar de baja un servicio, comprobamos primero que no este de baja ya, y luego ponemos false
    function BajaServicio(string memory _nombre) public UnicamenteAseguradora(msg.sender){
        require(ServicioEstado(_nombre) == true , "Ya esta de baja");
        MapServicios[_nombre].operativo = false;
        emit EventBajaServicio(_nombre);
    }

    // Funcion para conseguir el precio de un servicio, primero se comprueba que esté operativo
    function GetPrecioServicio(string memory _nombre) public view returns(uint){
        require (ServicioEstado(_nombre) == true , "No esta de alta");
        return MapServicios[_nombre].precioServicio;
    }

    // Funcion para ver que servicios están operativos actualmente, devuelve una array con estos
    function ConsultarServiciosActivos() public view returns(string[] memory) {
        // Se crea array auxiliar para ir poniendo los servicios activos
        string[] memory ServiciosActivos = new string[](Servicios.length);
        // Servirá para ir añadiendo parametros a la array auxiliar
        uint contador = 0;

        // Bucle donde vamos recorriendo la array Servicios, y si ese esta operativo lo añadimos a Servicios activos
        for(uint i = 0; i < Servicios.length; ++i)
        {
            if (ServicioEstado(Servicios[i])){
                ServiciosActivos[contador] = Servicios[i];
                ++contador;
            }
        }
        return ServiciosActivos;
    }

    // Funcion para que un cliente compre tokens IF, (funcion auxiliar) (Los ethers ya se han pagado)
    function ComprarTokens(address _cliente, uint _numTokens) public payable UnicamenteAsegurado(_cliente){
        // Miramos el balance de tokens de la Aseguradora(Propietario), es el balance del Smart Contract
        uint Balance = BalanceOf();
        // Comprobamos que tengamos suficientes tokens, y que lo que pida no sea negativo
        require (_numTokens <= Balance, "No hay tokens suficientes");
        require (_numTokens > 0, "Numero negativo");
        // Y le damos los tokens con la funcion transfer
        // El smart contract le da a msg.sender, numTokens
        // Dato importante = Los tokens NO van a la wallet del propietario, van a la direccion de su contrato
        // Básicamente para que solo pueda hacer con ellos funciones preestablecidas y no pueda sencillamente
        //      transferirlas donde quiera
        Token.transfer(msg.sender, _numTokens);
        emit EventTokensComprado(_numTokens);
    }

    // Funcion para incrementar el numero de tokens en circulacion
    function GenerarTokens(uint _numTokens) public UnicamenteAseguradora(msg.sender){
        Token.increaseTotalSupply(_numTokens);
    }

}


// -------------- CONTRATO LABORATORIO --------------------

contract Laboratorio is OperacionesBasicas {

    // Direcciones que necesitamos:
    // - Direccion del propietario del lab
    // - Direccion del contrato
    // - Direccion del contrato de la Aseguradora
    address public DireccionLab;
    address ContratoLab;
    address ContratoAseguradora;

    // Constructor para inicializar las tres direcciones previas
    constructor(address _Propietario, address _Contrato) public {
        DireccionLab = _Propietario;
        ContratoLab = address(this);
        ContratoAseguradora = _Contrato; 
    }

    // ----------- Structs --------------

    // Estructura para guardar los resultados
    struct Resultados
    {
        string Diagnostico;
        string codigo_IPFS;
    }

    // Estructura para guardar todos los servicios que ofrece un laboratorio
    struct ServiciosLab
    {
        string NombreServicio;
        uint PrecioServicio;
        bool Funcionamiento;
    }

    // ------------ Mapping y Arrays -------------

    // Mapping que relaciona que servicio ha soliticado un cliente
    mapping(address => string) public ServicioSolicitados;
    // Array para ver todas las wallets que han pedido servicio
    // Esta array se complemente con el mapping de arriba
    address[] public PeticionesServicios;
    // Relacion una wallet con la estructura de resultados
    mapping(address => Resultados) ResultadosServiciosLab;
    // Mapping para relacionar el nombre del servicio con la estructura con el precio y si esta operativo
    mapping(string => ServiciosLab) public ServiciosLaboratorio;
    // Toda la lista de serivicios, se complementa con el mapping de arriba para acceder a datos concretos como el precio
    string[] ServiciosDisponibles;

    // --------------- Eventos ------------------

    event EventServicioFuncionando(string, uint);
    event DarServicios(address, string);

    // ---------------- Modifiers -------------------

    modifier SoloLab(address _direccion){
        require (_direccion == DireccionLab, "Solo Lab");
        _;
    }

    // ---------------- Funciones ----------------------

    // Funcion para crear un nuevo servicio, con nombre y precio
    function NuevoServicioLab(string memory _nombre, uint precio) public SoloLab(msg.sender){
        // Lo metemos en el mapping y en la array
        ServiciosLaboratorio[_nombre] = ServiciosLab(_nombre, precio, true);
        ServiciosDisponibles.push(_nombre);
        // Emitimos evento
        emit EventServicioFuncionando(_nombre, precio);
    }

    // Funcion para devolver todos los servicios disponibles
    function ConsultarServicios() public view returns(string[] memory){
        return ServiciosDisponibles;
    }

    // Funcion para ver el precio del servicio que se le pase
    function ConsultarPrecioServicio(string memory _servicio) public view returns (uint){
        return ServiciosLaboratorio[_servicio].PrecioServicio;
    }

    // Funcion para dar un servicio
    function DarServicio(address _cliente, string memory _servicio) public {
        // Cogemos el contrato principal
        InsuranceFactory IF = InsuranceFactory(ContratoAseguradora);
        // Nos aseguramos que sea el cliente, y que esté autorizado
        IF.FuncionUnicamenteAsegurado(_cliente);
        // Miramos que el servicio esté operativo
        require(ServiciosLaboratorio[_servicio].Funcionamiento == true, "Servicio no disponible");
        // Lo ponemos en el mapping y la array
        ServicioSolicitados[_cliente] = _servicio;
        PeticionesServicios.push(msg.sender);
        // Emitimos evento
        emit DarServicios(_cliente, _servicio);
    }

    // Funcion el laboratorio puede subir los resultados
    function DarResultados(address _cliente, string memory _diagnostico, string memory _codigoIPFS) public SoloLab(msg.sender){
        ResultadosServiciosLab[_cliente] = Resultados(_diagnostico, _codigoIPFS);
    }

    // Funcion que devuelve los resultados
    function VisualizarResultados(address _direccion) public view returns(string memory _Diagnostico, string memory IPFS){
        _Diagnostico = ResultadosServiciosLab[_direccion].Diagnostico;
        IPFS = ResultadosServiciosLab[_direccion].codigo_IPFS;
    } 

}

// --------------- CONTRATO CLIENTE --------------------

contract InsuranceHealthRecord is OperacionesBasicas {

    // Enum para ver si esta de alta o de baja
    enum Estado{Alta, Baja}

    // Estructura con todos los datos del cliente
    // - Direccion del propietario
    // - Cuantos tokens tiene
    // - De alta o de baja
    // - Le pasamos el token IF
    // - Contrato de la Aseguradora(donde se guaradan los tokens IF)
    // - Direccion de la Aseguradora donde van los ethers
    struct Owner {
        address direccionPropietario;
        uint saldoPropietario;
        Estado estado;
        ERC20Basic numTokens;
        address ContratoAseguradora;
        address payable Aseguradora;
    }

    // --------- Structs ---------

    // Estructura para guardar los servicios que ha solicitado a la aseguradora
    struct ServiciosSolicitados
    {
        string nombreServicio;
        uint256 precioServicio;
        bool estadoServicio;
    }

    // Estructura para guardar los servicios solicitados a un laboratorio
    struct ServiciosSolicitadosLab
    {
        string nombreServicio;
        uint256 precioServicio;
        address dLab;
    }

    // Mapping y array que guardan los servicios que ha solicitado
    mapping(string => ServiciosSolicitados) historialCliente;
    ServiciosSolicitadosLab[] historialClienteLab;

    // Creamos al propietario del contrato osea el cliente
    Owner Propietario;

    // ------------ Eventos -----------------
    event SelfDestruct(address);
    event DevolverToken(address, uint);
    event ServicioPagado(address,string, uint);
    event PeticionServicioLab(address, address, string);

    // ----------------Modifiers----------------

    modifier Unicamente(address _direccion){
        require (msg.sender == Propietario.direccionPropietario);
        _;
    }

    // Funcion que devuelve el historial de laboratorios de un cliente
    function HistorialClienteLab() public view returns(ServiciosSolicitadosLab[] memory){
        return historialClienteLab;
    }

    // Funcion que devuelve los parametros de un servicio que el cliente ha solicitado
    // Esta funcion es auxiliar en el contrato principal para imprimir su historial
    function HistorialCliente(string memory _servicio) public view returns(string memory _nombreServicio, uint256 _precioServicio) {
        return (historialCliente[_servicio].nombreServicio, historialCliente[_servicio].precioServicio);
    }

    // Mira si un servicio esta operativo
    function ServicioEstadoCliente(string memory _servicio) public view returns(bool){
        return historialCliente[_servicio].estadoServicio;
    }

    // Constructor que inicializa todas las variables del Owner
    constructor(address _Cliente, ERC20Basic _token, address _ContratoInsurance, address payable _Propietario) public {

        Propietario.direccionPropietario = _Cliente;
        Propietario.saldoPropietario = 0;
        Propietario.estado = Estado.Alta;
        Propietario.numTokens = _token;
        Propietario.ContratoAseguradora = _ContratoInsurance;
        Propietario.Aseguradora = _Propietario;
        
    }

    // Funcion que emite el evento y destruye el contrato
    function darBaja() public Unicamente(msg.sender) {
        emit SelfDestruct(msg.sender);
        selfdestruct(msg.sender);
    }

    // Funcion para comprar tokens IF a partir de ETHER
    function CompraTokens(uint _numTokens) public payable Unicamente(msg.sender){
        // Miramos que pida un numero positivo de tokens IF
        require(_numTokens > 0, "Numero negativo");
        // Calculamos cual es el coste de esos tokens en ether
        uint Coste = CalcularPrecioToken(_numTokens);
        // Requerimos que los ethers que nos intenta pasar sea mas grande o igual al precio
        // Nota : Los ether que esta pasando van al contrato del Cliente!!
        require (Coste < msg.value, "No tienes suficientes ethers");
        // Calculamos cuando le tenemos que devolver
        uint returnValue = msg.value - Coste;
        // Se lo devolvemos
        // El contrato activa la transferencia al msg.sender osea al cliente
        msg.sender.transfer(returnValue);
        // Y le pasamos a la direccion del msg.sender los tokens IF
        InsuranceFactory(Propietario.ContratoAseguradora).ComprarTokens(msg.sender, _numTokens);
    }

    // Funcion auxiliar para ver cuantos tokens tiene
    // Nota : Los tokens los tiene el Smart Contrat no la wallet msg.sender!!
    function BalanceOf() public view Unicamente(msg.sender) returns(uint){
        return Propietario.numTokens.balanceOf(address(this));
    }

    // Funcion para devolverle los tokens IF a cambio de ether
    function DevolverTokens(uint _numTokens) public payable Unicamente(msg.sender){
        // Requerimos que pida un numero positivo, y que tenga balance suficiente
        require(_numTokens > 0, "Numero negativo");
        require(BalanceOf() >= _numTokens, "No tienes tantos tokens");
        // Transferimos los tokens IF al contrato de la aseguradora
        Propietario.numTokens.transfer(Propietario.ContratoAseguradora, _numTokens);
        // Le devolvemos los ether
        msg.sender.transfer(CalcularPrecioToken(_numTokens));
        // Emitimos evento
        emit DevolverToken(msg.sender, _numTokens);
    }

    // Funcion donde el cliente pide un servicio, ya tiene los tokens comprados
    function PeticionServicio(string memory _servicio) public Unicamente(msg.sender){
        // Usamos el contrato principal para ver que que este operativo el servicio
        require (InsuranceFactory(Propietario.ContratoAseguradora).ServicioEstado(_servicio) == true , "Servicio no está de alta");
        // Usamos el contrato principal para ver el precio
        uint pagoTokens = InsuranceFactory(Propietario.ContratoAseguradora).GetPrecioServicio(_servicio);
        // Requerimos que tenga sufiecientes tokens IF
        require(pagoTokens > BalanceOf(), "Necesitas mas tokens");
        // Hacemos la transferencia de tokens al Contrato de la Aseguradora
        Propietario.numTokens.transfer(Propietario.ContratoAseguradora, pagoTokens);
        // Añadimos el servicio al historial
        historialCliente[_servicio] = ServiciosSolicitados(_servicio, pagoTokens, true);
        // Emitimos evento
        emit ServicioPagado(msg.sender, _servicio, pagoTokens);

    }

    // Funcion para servicio especializado en laboratorio
    function PeticionServicioLaboratorio(string memory _servicio, address _direccionLab) public payable Unicamente(msg.sender){
        // Cojemos la Contrato Laboratorio para poder llamar a sus funciones
        Laboratorio contratoLab = Laboratorio(_direccionLab);
        // El cliente paga directamente en ethers, requreimos que la cantidad sea sufciente al precio del servicio
        require(msg.value == contratoLab.ConsultarPrecioServicio(_servicio) * 1 ether, "Operacion inválida");
        // Le damos a la funcion de servicio del contrato Laboratorio
        contratoLab.DarServicio(msg.sender, _servicio);
        // Le pago los ethers que van del contrato del cliente al CONTRATO del laboratorio
        payable(contratoLab.DireccionLab()).transfer(contratoLab.ConsultarPrecioServicio(_servicio) * 1 ether);
        // Añadimos al historial de laboratorios el servicio dado
        historialClienteLab.push(ServiciosSolicitadosLab(_servicio, contratoLab.ConsultarPrecioServicio(_servicio), _direccionLab));
        // Emitimos evento
        emit PeticionServicioLab(msg.sender, _direccionLab, _servicio);

    }
}