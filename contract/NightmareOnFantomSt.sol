/**************************************************************************************
 * This contract is an Experiment, and should be used at your own risk.
 * 
 * Author: Stinky Fi & Twisted Tech
 * Name:   Nightmare On Fantom St.
 * Desc:   Knock on our door, and say the magic words, if you dare!
 *         Minters will receive a Trick or a Treat, determined by on-chain randomness.
 *         The ghost haunting our contract has replaced the mint cap with a time cap. 
 *         When this contract is Haunted, You will be able to mint as many times as
 *         you want. Take advantage, this haunting will not last long! Once Halloween
 *         is over, no one will be able to mint from this contract again!
 *************************************************************************************/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NightmareOnFantomSt is ERC721Enumerable, ERC721Burnable, ReentrancyGuard, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    /*********************************************
     * Haunting (Minting starts):
     * Saturday, October 30, 2021 12:00:00 AM EST
     * Friday, October 29, 2021 9:00:00 PM PST
     * Saturday, October 30, 2021 4:00:00 AM GMT
     *********************************************/
    uint256 public haunting  = 1635480000;
    /*********************************************
     * Exorcism (Minting ends):
     * Monday, November 1, 2021 3:00:00 AM EST
     * Monday, November 1, 2021 12:00:00 PM PST
     * Monday, November 1, 2021 7:00:00 AM GMT
     *********************************************/
    uint256 public exorcism  = 1635750000;
     // Mint Price 1 FTM
    uint256 public price     = 1000000000000000000;

    // Trick Rarities
    string[] private tricks;
    string[] private rare_tricks;
    string[] private legendary_tricks;
    // Treat Rarities
    string[] private treats;
    string[] private rare_treats;
    string[] private legendary_treats;
    
    address public beneficiary;
    //Free mints
    mapping (address => uint256) public winner;
    
    event NaughtyList(address indexed _winner, uint256 _tokenId, uint256 _date);
    
    constructor(address _beneficiary) ERC721("Nightmare On Fantom St", "NOFS") {
        beneficiary = _beneficiary;
    }

    function setTrickBag(string[] memory _common, string[] memory _rare, string[] memory _legendary) public onlyOwner {
        tricks = _common;
        rare_tricks = _rare;
        legendary_tricks = _legendary;
    }
    
    function setTreatBag(string[] memory _common, string[] memory _rare, string[] memory _legendary) public onlyOwner {
        treats = _common;
        rare_treats = _rare;
        legendary_treats = _legendary;
    }
    
   /************************************************************* 
    * Desc: If you won
    *      After using your freebie, you can use claimHandfull.
    ***********************************************************/
    function contestWinner() public nonReentrant {
        uint8 result;
        bool _haunting = witchingHour();
        require(_haunting, "This Contract is no longer Haunted");
        require(winner[msg.sender] > 0, "Your name is not on the list, rejected.");
        for(uint256 i = 1; i <= winner[msg.sender]; i++)
        {
            _tokenIds.increment();
            _safeMint(_msgSender(), _tokenIds.current());
            
            result = bowlGrab(_tokenIds.current());
            if(result == 1 || result == 2){
                emit NaughtyList(msg.sender, _tokenIds.current(), block.timestamp);
            }
        }
        delete winner[msg.sender];
    }
    
	/************************************************************* 
     * Desc: If you won
     *      After using your freebie, you can use claimHandfull.
     ***********************************************************/
    function claim(uint256 _mintAmount) public payable nonReentrant {
	    uint8 result;
        bool _haunting = witchingHour();
        require(_haunting, "This Contract is no longer Haunted");
        uint256 _bundle = _mintAmount * price;
        require(_bundle == msg.value, "Incorrect payment amount");
        
        for(uint256 i = 0; i < _mintAmount; i++)
        {
            _tokenIds.increment();
            _safeMint(_msgSender(), _tokenIds.current());
            result = bowlGrab(_tokenIds.current());
            if(result == 1 || result == 2){
                emit NaughtyList(msg.sender, _tokenIds.current(), block.timestamp);
            }
        }
        
        payable(beneficiary).transfer(_bundle);
    }

    
    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        require(_tokenId <= _tokenIds.current(), "TokenID Has not been minted yet");
        return reveal(_tokenId);
    }
    
    /***********************************************************
     * random function found in $LOOT.
     ***********************************************************/
    function random(uint256 _tokenId, string memory _keyPrefix) internal pure returns (uint256) {
        bytes memory abiEncoded = abi.encodePacked(_keyPrefix, toString(_tokenId));
        return uint256(keccak256(abiEncoded));
    }
    
    /*************************************************
     * Desc: Inspired by $FLOOT ($LOOT derivative)
     *       Dice Roll 1:
     *          1/4 change of a trick
     *          3/4 change of a treat
     *       Dice Roll 2:
     *          1/8 change of upgrade to RARE
     *       Dice Roll 3(if got RARE):
     *          1/12 change of LEGENDARY
     **************************************************/
    function bowlGrab(uint256 _tokenId) internal pure returns (uint8) {
        uint256 diceRoll = random(_tokenId, "Trick-Or-Treat");

        if(diceRoll % 4 == 0)
        {
            diceRoll = random(_tokenId, "Smell-My-Feet");
            //Trick
            if(diceRoll % 8 == 0) // Rare 
            {   
                diceRoll = random(_tokenId, "Good-To-Eat");
                if(diceRoll % 12 == 0) //legendary Trick
                    return 1;
                return 3;
            }
            return 5;
        }
        else
        {
            diceRoll = random(_tokenId, "Smell-My-Feet");
            //Treat
            if(diceRoll % 8 == 0) //Rare Treat
            {
                diceRoll = random(_tokenId, "Good-To-Eat");
                if(diceRoll % 12 == 0)
                    return 2;  
                return 4;   
            }
            return 6;
        }
    }     
     

	/************************************
     * Desc: Determine Type and Rarity
    ************************************/         
    function reveal(uint256 _tokenId) internal view returns (string memory) {
        uint8 result = bowlGrab(_tokenId);
        
        if(result == 5)
            return tricks[_tokenId % tricks.length];
        else if (result == 3)
            return rare_tricks[_tokenId % tricks.length];
        else if (result == 1)
            return legendary_tricks[_tokenId % legendary_tricks.length];
        else if (result == 2)
            return legendary_treats[_tokenId % legendary_treats.length];
        else if (result == 4)
            return rare_treats[_tokenId % rare_treats.length];
        else
            return treats[_tokenId % treats.length];
    }
    
    
    // From $FLOOT
    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
        if (value == 0) {
            return "0";
        }

        uint256 temp = value;
        uint256 digits;

        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);

        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }
    
    /**********************************************************
     * Desc: All of the minting functions, will only operate
     *       during Halloween weekend 2021
     *********************************************************/
    function witchingHour() public view returns (bool) {
        if(block.timestamp >= haunting && block.timestamp < exorcism)
            {return true;}
        else
            {return false;}
    }
    
    /**********************************************
     * Desc: Contest Winners and Partnerships
     *********************************************/
    function assignWinners(address[] memory _winners, uint256 winnings) public onlyOwner {
        for (uint i=0; i < _winners.length; i++) {
            winner[_winners[i]] = winnings;
        }
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);

        // do stuff before every transfer
        // e.g. check that vote (other than when minted) 
        // being transferred to registered candidate
    }
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}