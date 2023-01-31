/**
           _______                   _____                    _____                    _____                _____                   _______         
          /::\    \                 /\    \                  /\    \                  /\    \              /\    \                 /::\    \        
         /::::\    \               /::\____\                /::\    \                /::\    \            /::\    \               /::::\    \       
        /::::::\    \             /:::/    /               /::::\    \              /::::\    \           \:::\    \             /::::::\    \      
       /::::::::\    \           /:::/    /               /::::::\    \            /::::::\    \           \:::\    \           /::::::::\    \     
      /:::/~~\:::\    \         /:::/    /               /:::/\:::\    \          /:::/\:::\    \           \:::\    \         /:::/~~\:::\    \    
     /:::/    \:::\    \       /:::/    /               /:::/__\:::\    \        /:::/  \:::\    \           \:::\    \       /:::/    \:::\    \   
    /:::/    / \:::\    \     /:::/    /               /::::\   \:::\    \      /:::/    \:::\    \          /::::\    \     /:::/    / \:::\    \  
   /:::/____/   \:::\____\   /:::/    /      _____    /::::::\   \:::\    \    /:::/    / \:::\    \        /::::::\    \   /:::/____/   \:::\____\ 
  |:::|    |     |:::|    | /:::/____/      /\    \  /:::/\:::\   \:::\    \  /:::/    /   \:::\    \      /:::/\:::\    \ |:::|    |     |:::|    |
  |:::|____|     |:::|____||:::|    /      /::\____\/:::/__\:::\   \:::\____\/:::/____/     \:::\____\    /:::/  \:::\____\|:::|____|     |:::|    |
   \:::\   _\___/:::/    / |:::|____\     /:::/    /\:::\   \:::\   \::/    /\:::\    \      \::/    /   /:::/    \::/    / \:::\    \   /:::/    / 
    \:::\ |::| /:::/    /   \:::\    \   /:::/    /  \:::\   \:::\   \/____/  \:::\    \      \/____/   /:::/    / \/____/   \:::\    \ /:::/    /  
     \:::\|::|/:::/    /     \:::\    \ /:::/    /    \:::\   \:::\    \       \:::\    \              /:::/    /             \:::\    /:::/    /   
      \::::::::::/    /       \:::\    /:::/    /      \:::\   \:::\____\       \:::\    \            /:::/    /               \:::\__/:::/    /    
       \::::::::/    /         \:::\__/:::/    /        \:::\   \::/    /        \:::\    \           \::/    /                 \::::::::/    /     
        \::::::/    /           \::::::::/    /          \:::\   \/____/          \:::\    \           \/____/                   \::::::/    /      
         \::::/____/             \::::::/    /            \:::\    \               \:::\    \                                     \::::/    /       
          |::|    |               \::::/    /              \:::\____\               \:::\____\                                     \::/____/        
          |::|____|                \::/____/                \::/    /                \::/    /                                      ~~              
           ~~                       ~~                       \/____/                  \/____/                                                       
  Developer: Apeiron                                                                                                                                                
  Telegram: https://t.me/OxApeiron                                                                                                                                                
  ENS: 0xapeiron.eth                                                                                                                                                
  Wallet: 0xF3f1BADD2b039799De0023D78c570002b6E89346                                                                                                                                                
  ---------------------------------------------------
  The Quecto Repository is an open source, MIT-licensed smart contract repository on Github. They are made with the intent to be used & taken inspiration from by anyone.
  These smart contracts are not audited.
  Usage and inspiration from this smart contract are not the responsibility of the original developer (Apeiron).
  ---------------------------------------------------
  This is a yield farm smart contract, re-using BNBMiner code with many differences, a ROI easy to change, share / bits burn on withdraw, daily rewards cutoff and upgradability.
**/

// SPDX-License-Identifier: MIT

/**
 */

pragma solidity ^0.8.17; // solhint-disable-line

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Miner is UUPSUpgradeable, OwnableUpgradeable {
    using SafeMath for uint256;

    uint256 PSN = 10000;
    uint256 PSNH = 5000;
    bool public initialized = false;

    address public marketing;
    address public influencer;
    address public dispatcher;

    mapping(address => uint256) public shares;
    mapping(address => uint256) public ownedBits;
    mapping(address => uint256) public lastConvert;
    mapping(address => uint256) public deposited;
    mapping(address => uint256) public withdrawn;

    uint256 public marketBit;

    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;

    uint16 internal constant PERCENT_DIVIDER = 1e4;
    uint16 internal constant SHARES_TO_BURN = 600;

    // TOTAL DEPOSIT FEES: 5%
    uint256 public constant FEE_DEPOSIT_OWNER = 150; // 1.50%
    uint256 public constant FEE_DEPOSIT_DISPATCHER = 100; // 1.00%
    uint256 public constant FEE_DEPOSIT_MARKETING = 150; // 1.50%
    uint256 public constant FEE_DEPOSIT_INFLUENCER = 100; // 1.00%

    // TOTAL WITHDRAW FEES: 10%
    uint256 public constant FEE_WITHDRAW_OWNER = 250; // 2.50%
    uint256 public constant FEE_WITHDRAW_DISPATCHER = 150; // 1.50%
    uint256 public constant FEE_WITHDRAW_MARKETING = 400; // 4.00%
    uint256 public constant FEE_WITHDRAW_INFLUENCER = 200; // 2.00%

    uint256 public constant BIT_TO_CONVERT_1SHARE = 7776000;
    uint256 public constant DAILY_INTEREST = 1000; // 1.000% daily ROI

    uint256 public unlock_date = 0;

    function initialize() public initializer {
        require(!initialized, "Contract has already been initialized.");

        initialized = true;
        influencer = address(0x0);
        marketing = address(0x0);
        dispatcher = address(0x0);
    }

    event BuyBits(address indexed from, uint256 amount, uint256 bitBought);
    event CompoundBits(
        address indexed from,
        uint256 bitUsed,
        uint256 sharesReceived
    );
    event SellBits(address indexed from, uint256 amount);
    event BurnShares(address indexed from, uint256 sharesBurned);
    event UpgradableUnlockInitiated(uint256 unlock_date);
    event UpgradableUnlockCancelled();

    modifier onlyUnlocked() {
        require(unlock_date != 0, "Upgrade not possible.");
        require(block.timestamp >= unlock_date, "Upgrade not possible yet.");
        _;
    }

    function _authorizeUpgrade(address)
        internal
        override
        onlyOwner
        onlyUnlocked
    {}

    function unlockUpgrade() external onlyOwner {
        require(block.timestamp < unlock_date, "Already unlocked.");

        unlock_date = block.timestamp + 15 days;

        emit UpgradableUnlockInitiated(unlock_date);
    }

    function cancelUpgrade() external onlyOwner {
        unlock_date = 0;

        emit UpgradableUnlockCancelled();
    }

    function burnShares(uint256 amount) public {
        require(
            amount > 0 && amount <= shares[msg.sender],
            "Incorrect share amount."
        );

        uint256 balance = shares[msg.sender];
        uint256 bits_to_burn = balance.mul(_getBitToShare());

        if (marketBit - bits_to_burn > 0) {
            marketBit = marketBit.sub(bits_to_burn);
        }

        shares[DEAD] = shares[DEAD].add(amount);
        shares[msg.sender] = shares[msg.sender].sub(amount);

        emit BurnShares(msg.sender, amount);
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function _getPercentage(uint256 value, uint256 percent)
        private
        pure
        returns (uint256)
    {
        return (value * percent) / PERCENT_DIVIDER;
    }

    function _getFeeDeposit(uint256 value) private returns (uint256) {
        uint256 feeOwner = _getPercentage(value, FEE_DEPOSIT_OWNER);
        uint256 feeMarketing = _getPercentage(value, FEE_DEPOSIT_MARKETING);
        uint256 feeDispatcher = _getPercentage(value, FEE_DEPOSIT_DISPATCHER);
        uint256 feeInfluencer = _getPercentage(value, FEE_DEPOSIT_INFLUENCER);

        payable(owner()).send(feeOwner);
        payable(dispatcher).send(feeDispatcher);
        payable(influencer).send(feeInfluencer);
        payable(marketing).send(feeMarketing);

        return value - feeOwner - feeMarketing - feeInfluencer - feeDispatcher;
    }

    function _getFeeDepositSimple(uint256 value)
        private
        pure
        returns (uint256)
    {
        uint256 feeOwner = _getPercentage(value, FEE_DEPOSIT_OWNER);
        uint256 feeMarketing = _getPercentage(value, FEE_DEPOSIT_MARKETING);
        uint256 feeDispatcher = _getPercentage(value, FEE_DEPOSIT_DISPATCHER);
        uint256 feeInfluencer = _getPercentage(value, FEE_DEPOSIT_INFLUENCER);

        return value - feeOwner - feeMarketing - feeInfluencer - feeDispatcher;
    }

    function _getFeeWithdraw(uint256 value) private returns (uint256) {
        uint256 feeOwner = _getPercentage(value, FEE_WITHDRAW_OWNER);
        uint256 feeMarketing = _getPercentage(value, FEE_WITHDRAW_MARKETING);
        uint256 feeDispatcher = _getPercentage(value, FEE_WITHDRAW_DISPATCHER);
        uint256 feeInfluencer = _getPercentage(value, FEE_WITHDRAW_INFLUENCER);

        payable(owner()).send(feeOwner);
        payable(dispatcher).send(feeDispatcher);
        payable(influencer).send(feeInfluencer);
        payable(marketing).send(feeMarketing);

        return value - feeOwner - feeMarketing - feeInfluencer - feeDispatcher;
    }

    function _getFeeWithdrawSimple(uint256 value)
        private
        pure
        returns (uint256)
    {
        uint256 feeOwner = _getPercentage(value, FEE_WITHDRAW_OWNER);
        uint256 feeMarketing = _getPercentage(value, FEE_WITHDRAW_MARKETING);
        uint256 feeDispatcher = _getPercentage(value, FEE_WITHDRAW_DISPATCHER);
        uint256 feeInfluencer = _getPercentage(value, FEE_WITHDRAW_INFLUENCER);

        return value - feeOwner - feeMarketing - feeInfluencer - feeDispatcher;
    }

    function _getBitToShare() private pure returns (uint256) {
        return 7776e6 / DAILY_INTEREST;
    }

    function _getBitSinceLastConvert(address adr)
        private
        view
        returns (uint256)
    {
        uint256 secondsPassed = min(
            2 days,
            SafeMath.sub(block.timestamp, lastConvert[adr])
        );

        return SafeMath.mul(secondsPassed, shares[adr]);
    }

    function getBitToShare() external pure returns (uint256) {
        return _getBitToShare();
    }

    function seedMarket() public payable onlyOwner {
        require(!initialized, "Already initialized.");
        require(marketBit == 0);
        initialized = true;
        marketBit = 108000000000;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getShares() public view returns (uint256) {
        return shares[msg.sender];
    }

    function getBits() public view returns (uint256) {
        return
            SafeMath.add(
                ownedBits[msg.sender],
                _getBitSinceLastConvert(msg.sender)
            );
    }

    function getLastConvert() public view returns (uint256) {
        return lastConvert[msg.sender];
    }

    function getBitSinceLastConvert(address adr)
        external
        view
        returns (uint256)
    {
        return _getBitSinceLastConvert(adr);
    }

    function setDispatcher(address _dispatcher) external onlyOwner {
        dispatcher = _dispatcher;
    }

    function setInfluencer(address _influencer) external onlyOwner {
        influencer = _influencer;
    }

    function setMarketing(address _marketing) external onlyOwner {
        marketing = _marketing;
    }

    function compoundBits() public {
        require(initialized, "Contract is not initialized yet.");

        uint256 bitUsed = getBits();

        uint256 newShares = bitUsed.div(_getBitToShare());
        shares[msg.sender] = shares[msg.sender].add(newShares);
        ownedBits[msg.sender] = 0;
        lastConvert[msg.sender] = block.timestamp;

        marketBit = marketBit.add(bitUsed.div(5));

        emit CompoundBits(msg.sender, bitUsed, newShares);
    }

    function sellBits() external {
        require(initialized, "Contract is not initialized yet.");

        uint256 sharesOwned = shares[msg.sender];

        require(sharesOwned > 0, "You must own shares to claim.");

        uint256 hasBit = getBits();
        uint256 bitValue = calculateBitSell(hasBit);
        uint256 fee = _getFeeWithdrawSimple(bitValue);
        uint256 sharesToBurn = (sharesOwned.mul(SHARES_TO_BURN)).div(
            PERCENT_DIVIDER
        );

        ownedBits[msg.sender] = 0;
        lastConvert[msg.sender] = block.timestamp;
        marketBit = marketBit.add(hasBit);
        withdrawn[msg.sender] += bitValue.sub(fee);

        if (sharesOwned >= 100) {
            burnShares(sharesToBurn); // burn 6% shares
        }

        fee = _getFeeWithdraw(bitValue);

        payable(msg.sender).transfer(bitValue.sub(fee));

        emit SellBits(msg.sender, bitValue);
    }

    function buyBits() external payable {
        require(msg.value > 0, "You need to enter an amount.");
        require(initialized, "Contract is not initialized yet.");

        uint256 bitBought = calculateBitBuy(
            msg.value,
            getBalance().sub(msg.value)
        );
        bitBought = bitBought.sub(_getFeeDepositSimple(bitBought));
        ownedBits[msg.sender] += bitBought;
        deposited[msg.sender] += _getFeeDepositSimple(msg.value);

        compoundBits();

        _getFeeDeposit(msg.value);

        emit BuyBits(msg.sender, msg.value, bitBought);
    }

    function calculateTrade(
        uint256 rt,
        uint256 rs,
        uint256 bs
    ) public view returns (uint256) {
        return
            SafeMath.div(
                SafeMath.mul(PSN, bs),
                SafeMath.add(
                    PSNH,
                    SafeMath.div(
                        SafeMath.add(
                            SafeMath.mul(PSN, rs),
                            SafeMath.mul(PSNH, rt)
                        ),
                        rt
                    )
                )
            );
    }

    function calculateBitSell(uint256 bit) public view returns (uint256) {
        return calculateTrade(bit, marketBit, getBalance());
    }

    function calculateBitBuy(uint256 token, uint256 contractBalance)
        public
        view
        returns (uint256)
    {
        return calculateTrade(token, contractBalance, marketBit);
    }

    function calculateBitBuySimple(uint256 eth) public view returns (uint256) {
        return calculateBitBuy(eth, getBalance());
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    receive() external payable {}
}