import { Contract, Wallet } from 'ethers'
import { Web3Provider } from 'ethers/providers'
import { defaultAbiCoder } from 'ethers/utils'
import { deployContract } from 'ethereum-waffle'

import { expandTo18Decimals } from './utilities'

import ERC20 from '../../build/ERC20.json'
import WETH9 from '../../build/WETH9.json'
import MagicornSwapFactory from '../../build/MagicornSwapFactory.json'
import MagicornSwapPair from '../../build/MagicornSwapPair.json'
import MagicornSwapDeployer from '../../build/MagicornSwapDeployer.json'
import MagicornSwapFeeSetter from '../../build/MagicornSwapFeeSetter.json'
import MagicornSwapFeeReceiver from '../../build/MagicornSwapFeeReceiver.json'

interface FactoryFixture {
  factory: Contract
  feeSetter: Contract
  feeReceiver: Contract
  WETH: Contract
}

const overrides = {
  gasLimit: 9999999
}

export async function factoryFixture(provider: Web3Provider, [magicorndao, ethReceiver]: Wallet[]): Promise<FactoryFixture> {
  const WETH = await deployContract(magicorndao, WETH9)
  const magicornSwapDeployer = await deployContract(
    magicorndao, MagicornSwapDeployer, [ ethReceiver.address, magicorndao.address, WETH.address, [], [], [], ], overrides
  )
  await magicorndao.sendTransaction({to: magicornSwapDeployer.address, gasPrice: 0, value: 1})
  const deployTx = await magicornSwapDeployer.deploy()
  const deployTxReceipt = await provider.getTransactionReceipt(deployTx.hash);
  const factoryAddress = deployTxReceipt.logs !== undefined
    ? defaultAbiCoder.decode(['address'], deployTxReceipt.logs[0].data)[0]
    : null
  const factory = new Contract(factoryAddress, JSON.stringify(MagicornSwapFactory.abi), provider).connect(magicorndao)
  const feeSetterAddress = await factory.feeToSetter()
  const feeSetter = new Contract(feeSetterAddress, JSON.stringify(MagicornSwapFeeSetter.abi), provider).connect(magicorndao)
  const feeReceiverAddress = await factory.feeTo()
  const feeReceiver = new Contract(feeReceiverAddress, JSON.stringify(MagicornSwapFeeReceiver.abi), provider).connect(magicorndao)
  return { factory, feeSetter, feeReceiver, WETH }
}

interface PairFixture extends FactoryFixture {
  token0: Contract
  token1: Contract
  pair: Contract
  wethPair: Contract
}

export async function pairFixture(provider: Web3Provider, [magicorndao, wallet, ethReceiver]: Wallet[]): Promise<PairFixture> {
  const tokenA = await deployContract(wallet, ERC20, [expandTo18Decimals(10000)], overrides)
  const tokenB = await deployContract(wallet, ERC20, [expandTo18Decimals(10000)], overrides)
  const WETH = await deployContract(wallet, WETH9)
  await WETH.deposit({value: expandTo18Decimals(1000)})
  const token0 = tokenA.address < tokenB.address ? tokenA : tokenB
  const token1 = token0.address === tokenA.address ? tokenB : tokenA
  
  const magicornSwapDeployer = await deployContract(
    magicorndao, MagicornSwapDeployer, [
      ethReceiver.address,
      magicorndao.address,
      WETH.address,
      [token0.address, token1.address],
      [token1.address, WETH.address],
      [15, 15],
    ], overrides
  )
  await magicorndao.sendTransaction({to: magicornSwapDeployer.address, gasPrice: 0, value: 1})
  const deployTx = await magicornSwapDeployer.deploy()
  const deployTxReceipt = await provider.getTransactionReceipt(deployTx.hash);
  const factoryAddress = deployTxReceipt.logs !== undefined
    ? defaultAbiCoder.decode(['address'], deployTxReceipt.logs[0].data)[0]
    : null
  
  const factory = new Contract(factoryAddress, JSON.stringify(MagicornSwapFactory.abi), provider).connect(magicorndao)
  const feeSetterAddress = await factory.feeToSetter()
  const feeSetter = new Contract(feeSetterAddress, JSON.stringify(MagicornSwapFeeSetter.abi), provider).connect(magicorndao)
  const feeReceiverAddress = await factory.feeTo()
  const feeReceiver = new Contract(feeReceiverAddress, JSON.stringify(MagicornSwapFeeReceiver.abi), provider).connect(magicorndao)
  const pair = new Contract(
     await factory.getPair(token0.address, token1.address),
     JSON.stringify(MagicornSwapPair.abi), provider
   ).connect(magicorndao)
  const wethPair = new Contract(
     await factory.getPair(token1.address, WETH.address),
     JSON.stringify(MagicornSwapPair.abi), provider
   ).connect(magicorndao)

  return { factory, feeSetter, feeReceiver, WETH, token0, token1, pair, wethPair }
}
