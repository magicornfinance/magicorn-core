pragma solidity =0.5.16;

import './interfaces/IMagicornSwapFactory.sol';

contract MagicornSwapFeeSetter {
    address public owner;
    mapping(address => address) public pairOwners;
    IMagicornSwapFactory public factory;
  
    constructor(address _owner, address _factory) public {
        owner = _owner;
        factory = IMagicornSwapFactory(_factory);
    }

    function transferOwnership(address newOwner) external {
        require(msg.sender == owner, 'MagicornSwapFeeSetter: FORBIDDEN');
        owner = newOwner;
    }
    
    function transferPairOwnership(address pair, address newOwner) external {
        require(msg.sender == owner, 'MagicornSwapFeeSetter: FORBIDDEN');
        pairOwners[pair] = newOwner;
    }

    function setFeeTo(address feeTo) external {
        require(msg.sender == owner, 'MagicornSwapFeeSetter: FORBIDDEN');
        factory.setFeeTo(feeTo);
    }

    function setFeeToSetter(address feeToSetter) external {
        require(msg.sender == owner, 'MagicornSwapFeeSetter: FORBIDDEN');
        factory.setFeeToSetter(feeToSetter);
    }
    
    function setProtocolFee(uint8 protocolFeeDenominator) external {
        require(msg.sender == owner, 'MagicornSwapFeeSetter: FORBIDDEN');
        factory.setProtocolFee(protocolFeeDenominator);
    }
    
    function setSwapFee(address pair, uint32 swapFee) external {
        require((msg.sender == owner) || ((msg.sender == pairOwners[pair])), 'MagicornSwapFeeSetter: FORBIDDEN');
        factory.setSwapFee(pair, swapFee);
    }
}
