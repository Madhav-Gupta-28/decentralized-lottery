import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {


  solidity:{
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },


  networks:{
    mumbai:{
      url:"https://polygon-mumbai.g.alchemy.com/v2/wYPWPW48VmKGvFFdz4_-c5lwAAkS9XaM",
      accounts:["78d217cddc344385c3f5555253b95fcf119c1e2c5216a12e8a8aeec2dc03c52f"],
      gas:'auto'
    }
  }

};

export default config;
