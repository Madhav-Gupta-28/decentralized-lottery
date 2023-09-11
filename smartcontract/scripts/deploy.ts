import { ethers } from "hardhat";

async function main() {

const LINK_TOKEN = "0x326C977E6efc84E512bB9C30f76E30c160eD06FB";
const VRF_COORDINATOR = "0x8C7382F9D8f56b33781fE506E897a4F1e2d17255";
const KEY_HASH =
  "0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4";
const FEE = ethers.parseEther("0.0001");


// deploying aift token contract 
  const Aifttoken = await ethers.getContractFactory("AIFTToken"); //0x16883bf187DC1B1CacB875080632ef78cd3f734D
  const aifttoken = await Aifttoken.deploy();

  console.log("AIFTToken deployed to:", aifttoken.target);

 // deploying aift contarct
 const Aift = await ethers.getContractFactory("AIFT"); // 0xd7b4b4ffc93249501cB1bd541F340f9041F97522
 const aift = await Aift.deploy();

 console.log("AIFT depllotteryContractoyed to:", aift.target);



  // deploying lottery contract
  const lottery = await ethers.getContractFactory("Lottery"); // 0x43791e7236C7A24cFf978aEe06b62E59A1265724
  const lotteryContract = await lottery.deploy(VRF_COORDINATOR , LINK_TOKEN , KEY_HASH , FEE ,  aift.target ,  aifttoken.target);

  console.log("lotteryContract deployed to:", lotteryContract.target);


  

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
