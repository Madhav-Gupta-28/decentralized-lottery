"use client";

import React from 'react'
import { ChakraProvider, Mark } from '@chakra-ui/react';
import Header from "@/components/Header/Header"
import LotteryMarketplace from '@/components/LotteryPlace/lotteryMarketplace';

import '@rainbow-me/rainbowkit/styles.css';
import {
  getDefaultWallets,
  RainbowKitProvider,
} from '@rainbow-me/rainbowkit';
import { configureChains, createConfig, sepolia, WagmiConfig } from 'wagmi';
import {
  polygonMumbai,
  goerli,
} from 'wagmi/chains';
import { alchemyProvider } from 'wagmi/providers/alchemy';
import { publicProvider } from 'wagmi/providers/public';

import "@rainbow-me/rainbowkit/styles.css";


const { chains, publicClient } = configureChains(
  [polygonMumbai , sepolia , goerli],
  [
    alchemyProvider({ apiKey :  "https://polygon-mumbai.g.alchemy.com/v2/wYPWPW48VmKGvFFdz4_-c5lwAAkS9XaM" }),
    publicProvider()
  ]
);
const { connectors } = getDefaultWallets({
  appName: 'Gas less Lottery Decentralized Application',
  projectId: 'b330ff589c7d5e5b8f99c34eb9f70bc8',
  chains
});
const wagmiConfig = createConfig({
  autoConnect: true,
  connectors,
  publicClient
})

export default function Home() {
  return (
    <>
    <WagmiConfig config={wagmiConfig}>
   <RainbowKitProvider chains={chains}>
   <ChakraProvider>
      <Header/>
      <LotteryMarketplace/>
    </ChakraProvider>

   </RainbowKitProvider>
    </WagmiConfig>
    

    </>
    
  )
}
