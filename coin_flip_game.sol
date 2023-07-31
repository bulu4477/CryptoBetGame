pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

contract cion_flip_game is Ownable {
    uint256 public maxChips;      //最大下注
    uint256 public minChips;      //最小下注
    uint256 public feeRate;

    enum GameStatus{ PENDING, STARTED, ENDED }     //对战状态
    
    //游戏类
    struct Game {
        GameStatus gameStatus;    
        address player1;
        address player2;
        uint256 player1Chips;
        uint256 player2Chips;
        address winner;
    }

    mapping(address => bool) public inGame;      //玩家是否在游戏中

    Game[] public gameInfo;

    event GameCreated(uint256 gameId, address player1);
    event GameJoined(uint256 gameId, address player2);
    event GameFinished(uint256 gameId, address winner, uint256 totalbet);

    constructor() payable {
        maxChips = 100 * 10 **18;
        minChips = 1 * 10 **18;
        feeRate = 2;

        gameInfo.push(Game(GameStatus.PENDING, address(0), address(0), 0, 0, address(0)));
    }

    //改变最大下注值
    function changeMaxChips(uint256 _newMaxChips) public onlyOwner() {
        maxChips = _newMaxChips;
    }

    //改变最小下注值
    function changeMinChips(uint256 _newMinChips) public onlyOwner() {
        minChips = _newMinChips;
    }
    
    //改变费率
    function changeFeeRate(uint256 _newFeeRate) public onlyOwner() {
        feeRate = _newFeeRate;
    }

    //创建游戏，返回gameID
    function createGame() external payable returns(uint256) {
        require(msg.value >= minChips && msg.value <= maxChips, "Invalid bet amount");
        require(!inGame[msg.sender], "You are already in game.");

        Game memory _game = Game(
            GameStatus.PENDING,
            msg.sender,
            address(0),
            msg.value,
            0,
            address(0)
        );
        gameInfo.push(_game);
        uint256 gameID = gameInfo.length - 1;

        emit GameCreated(gameInfo.length - 1, msg.sender);
        return gameID;
    }

    //根据gameID加入游戏
    function joinGame(uint256 gameId) external payable {
        require(gameId < gameInfo.length, "Invalid game id");
        Game storage _game = gameInfo[gameId];
        require(_game.gameStatus == GameStatus.PENDING, "Game has started");
        require(msg.sender != _game.player1, "You cannot join your own game");
        require(_game.player2 == address(0), "Game already has two players");
        require(msg.value >= minChips && msg.value <= maxChips, "Invalid bet amount");

        _game.player2 = msg.sender;
        _game.player2Chips = msg.value;
        beginGame(gameId);
        emit GameJoined(gameId, msg.sender);
    }

    //双方加入游戏后开始游戏
    function beginGame(uint256 gameId) internal {
        Game storage _game = gameInfo[gameId];
        inGame[_game.player1] = true;
        inGame[_game.player2] = true;
        _game.gameStatus = GameStatus.STARTED;

        uint256 _totalBet = (_game.player1Chips + _game.player2Chips) / 1 * 10 ** 18;
        uint256 randomNum = generateRandomNumber(_game.player1, _game.player2, _game.player1Chips, _game.player2Chips, _totalBet);
        if(randomNum <= _game.player1Chips / 1 * 10 ** 18) {
            finishGame(gameId, _game.player1);
        } else {
            finishGame(gameId, _game.player2);
        }
    }

    //结算结果
    function finishGame(uint256 gameId, address _winner) internal {
        Game storage _game = gameInfo[gameId];
        require(_game.gameStatus == GameStatus.STARTED, "Game has not started");
        _game.winner = _winner;
        uint256 totalBet = (_game.player1Chips + _game.player2Chips * (100 - feeRate) / 100);
        _game.gameStatus = GameStatus.ENDED;
        _winner.call{value: totalBet}("");
        inGame[_game.player1] = false;
        inGame[_game.player2] = false;
        emit GameFinished(gameId, _winner, totalBet);
    }

    receive() external payable {}

    function withdraw(uint256 withdrawFee) public onlyOwner() {
       payable(owner()).transfer(withdrawFee);
    }

    //根据双方地址和下注获取随机数
    function generateRandomNumber(address address1, address address2, uint256 number1, uint256 number2, uint256 num) internal view returns (uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(address1, address2, number1, number2)));
        uint256 random = uint256(keccak256(abi.encodePacked(seed, block.timestamp)));
        return random % num + 1;
    }
}