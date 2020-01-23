pragma solidity >= 0.5.0 < 0.7.0;
import 'node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol';
import 'node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol';
import "node_modules/openzeppelin-solidity/contracts/GSN/Context.sol";
contract Series is Ownable {

  using SafeMath for uint;

  string public title;
  uint public pledgePerEpisode;
  uint public minimumPublicationPeriod;
  mapping(address => uint)public pledges;
  address payable[] pledgers;
  mapping(uint => string)public publishedEpisodes;
  uint public episodeCounter;
  uint public lastPublicationBlock;

  event NewPledger(address payable pledger);
  event NewPledge(address payable indexed  pledger,uint pledge,uint totalPledge );
  event withdrawl(address payable indexed pledger,uint pledge);
  event newPublication(uint episodeId,string episodeLink,uint episodePay);
  event pledgeInsufficient(address payable indexed pledger,uint pledge);
  event seriesClosed(uint balanceBeforeClose);

  constructor(string memory _title, uint _pledgePerEpisode,uint _minimumPublicationPeriod) public {
    title = _title;
    pledgePerEpisode = _pledgePerEpisode;
    minimumPublicationPeriod = _minimumPublicationPeriod;
  }
  function pledge() public payable {
   require(pledges[msg.sender].add(msg.value) >= pledgePerEpisode,"pledge must be greater than pledge per episode");
  require((msg.sender != owner()),"Owner can not pledge on its own series");
  bool oldpledger = false;
  for(uint i = 0;i < pledgers.length;i++)
  {
  if(pledgers[i]==msg.sender)
  {
  oldpledger = true;
  break;
  }
  }
  if(!oldpledger)
  {
    pledgers.push(msg.sender);
    emit NewPledger(msg.sender);
  }
  pledges[msg.sender] = pledges[msg.sender].add(msg.value);
  emit NewPledge(msg.sender,msg.value,pledges[msg.sender]);
  }
  function withdraw() public{
  uint amount = pledges[msg.sender];
  if(amount > 0)
  {
    pledges[msg.sender] = 0;
    msg.sender.transfer(amount);
    emit withdrawl(msg.sender,amount);
    emit pledgeInsufficient(msg.sender,0);
  }
  }
  function publish(string memory episodeLink) public onlyOwner
  {
    require(lastPublicationBlock == 0 || block.number > lastPublicationBlock.add(minimumPublicationPeriod) ,"Owner can't publish soon");
   lastPublicationBlock = block.number;
   episodeCounter++;
   publishedEpisodes[episodeCounter] = episodeLink;

   uint episodePay = 0;
   for(uint i = 0;i < pledgers.length; i++)
   {
     if(pledges[pledgers[i]] >= pledgePerEpisode)
     {
       pledges[pledgers[i]] = pledges[pledgers[i]].sub(pledgePerEpisode);
       episodePay = episodePay.add(pledgePerEpisode);
       if(pledges[pledgers[i]] < pledgePerEpisode)
       {
         emit pledgeInsufficient(pledgers[i],pledges[pledgers[i]]);
       }
     }
   }
   owner().transfer(episodePay);
   emit newPublication(episodeCounter,episodeLink,episodePay);
  }
  function close() public onlyOwner{
     uint currentBalance = address(this).balance;
  for(uint i = 0;i < pledgers.length; i++)
  {
    uint amount = pledges[pledgers[i]];
    if(amount>0)
    {
    pledgers[i].transfer(amount);
  }
  }
  emit seriesClosed(currentBalance);
  selfdestruct(owner());
  }

  function totalPledgers() public view returns(uint)
  {
   return pledgers.length;
  }

  function activePledgers() public view returns(uint)
  {
    uint active = 0;
    for(uint i = 0;i < pledgers.length ; i++)
    {
      if(pledges[pledgers[i]]>=pledgePerEpisode)
      {
      active++;
      }
    }
    return active;
  }

  function nextEpisodePay() public view returns(uint)
  {
    uint episodePay = 0;
    for(uint i = 0;i < pledgers.length;i++)
    {
      if(pledges[pledgers[i]] >= pledgePerEpisode)
      {
        episodePay = episodePay.add(pledgePerEpisode);
      }
    }
    return episodePay;
  }

}