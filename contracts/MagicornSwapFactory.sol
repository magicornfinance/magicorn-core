pragma solidity =0.5.16;

import './interfaces/IMagicornSwapFactory.sol';
import './MagicornSwapPair.sol';

contract MagicornSwapFactory is IMagicornSwapFactory {
    address public feeTo;
    address public feeToSetter;
    uint8 public protocolFeeDenominator = 9; // uses ~10% of each swap fee
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(MagicornSwapPair).creationCode));

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'MagicornSwapFactory: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'MagicornSwapFactory: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'MagicornSwapFactory: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(MagicornSwapPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IMagicornSwapPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'MagicornSwapFactory: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'MagicornSwapFactory: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
    
    function setProtocolFee(uint8 _protocolFeeDenominator) external {
        require(msg.sender == feeToSetter, 'MagicornSwapFactory: FORBIDDEN');
        require(_protocolFeeDenominator > 0, 'MagicornSwapFactory: FORBIDDEN_FEE');
        protocolFeeDenominator = _protocolFeeDenominator;
    }
    
    function setSwapFee(address _pair, uint32 _swapFee) external {
        require(msg.sender == feeToSetter, 'MagicornSwapFactory: FORBIDDEN');
        IMagicornSwapPair(_pair).setSwapFee(_swapFee);
    }
}
