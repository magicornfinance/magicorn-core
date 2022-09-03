pragma solidity =0.5.16;

import './MagicornSwapFactory.sol';
import './interfaces/IMagicornSwapPair.sol';
import './MagicornSwapFeeSetter.sol';
import './MagicornSwapFeeReceiver.sol';


contract MagicornSwapDeployer {
    
    address payable public protocolFeeReceiver;
    address payable public magicorndaoAvatar;
    address public WETH;
    uint8 public state = 0;

    struct TokenPair {
        address tokenA;
        address tokenB;
        uint32 swapFee;
    }
    
    TokenPair[] public initialTokenPairs;

    event FeeReceiverDeployed(address feeReceiver);    
    event FeeSetterDeployed(address feeSetter);
    event PairFactoryDeployed(address factory);
    event PairDeployed(address pair);
        
    // Step 1: Create the deployer contract with all the needed information for deployment.
    constructor(
        address payable _protocolFeeReceiver,
        address payable _magicorndaoAvatar,
        address _WETH,
        address[] memory tokensA,
        address[] memory tokensB,
        uint32[] memory swapFees
    ) public {
        magicorndaoAvatar = _magicorndaoAvatar;
        WETH = _WETH;
        protocolFeeReceiver = _protocolFeeReceiver;
        for(uint8 i = 0; i < tokensA.length; i ++) {
            initialTokenPairs.push(
                TokenPair(
                    tokensA[i],
                    tokensB[i],
                    swapFees[i]
                )
            );
        }
    }
    
    // Step 2: Transfer ETH from the DXdao avatar to allow the deploy function to be called.
    function() external payable {
        require(state == 0, 'MagicornSwapDeployer: WRONG_DEPLOYER_STATE');
        require(msg.sender == magicorndaoAvatar, 'MagicornSwapDeployer: CALLER_NOT_FEE_TO_SETTER');
        state = 1;
    }
    
    // Step 3: Deploy MagicornSwapFactory and all initial pairs
    function deploy() public {
        require(state == 1, 'MagicornSwapDeployer: WRONG_DEPLOYER_STATE');
        MagicornSwapFactory magicornSwapFactory = new MagicornSwapFactory(address(this));
        emit PairFactoryDeployed(address(magicornSwapFactory));
        for(uint8 i = 0; i < initialTokenPairs.length; i ++) {
            address newPair = magicornSwapFactory.createPair(initialTokenPairs[i].tokenA, initialTokenPairs[i].tokenB);
            magicornSwapFactory.setSwapFee(newPair, initialTokenPairs[i].swapFee);
            emit PairDeployed(
                address(newPair)
            );
        }
        MagicornSwapFeeReceiver magicornSwapFeeReceiver = new MagicornSwapFeeReceiver(
            magicorndaoAvatar, address(magicornSwapFactory), WETH, protocolFeeReceiver, magicorndaoAvatar
        );
        emit FeeReceiverDeployed(address(magicornSwapFeeReceiver));
        magicornSwapFactory.setFeeTo(address(magicornSwapFeeReceiver));
        
        MagicornSwapFeeSetter magicornSwapFeeSetter = new MagicornSwapFeeSetter(magicorndaoAvatar, address(magicornSwapFactory));
        emit FeeSetterDeployed(address(magicornSwapFeeSetter));
        magicornSwapFactory.setFeeToSetter(address(magicornSwapFeeSetter));
        state = 2;
        msg.sender.transfer(address(this).balance);
    }
    
  
}
