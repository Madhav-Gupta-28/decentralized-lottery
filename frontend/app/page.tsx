"use client";

import React from 'react'
import { ChakraProvider, Mark } from '@chakra-ui/react';
import { ConnectButton } from '@rainbow-me/rainbowkit';
// import Header from '@/Component/Header/Header';
// import Marketplace from '@/Component/Marketplace/Marketplace';

import '@rainbow-me/rainbowkit/styles.css';
import {
  getDefaultWallets,
  RainbowKitProvider,
} from '@rainbow-me/rainbowkit';
import { configureChains, createConfig, WagmiConfig } from 'wagmi';
import {
  mainnet,
  polygon,
  optimism,
  arbitrum,
  base,
  zora,
  polygonMumbai,
} from 'wagmi/chains';
import { alchemyProvider } from 'wagmi/providers/alchemy';
import { publicProvider } from 'wagmi/providers/public';

import "@rainbow-me/rainbowkit/styles.css";


const { chains, publicClient } = configureChains(
  [polygonMumbai, polygon, optimism, arbitrum, base, zora],
  [
    alchemyProvider({ apiKey :  "https://polygon-mumbai.g.alchemy.com/v2/wYPWPW48VmKGvFFdz4_-c5lwAAkS9XaM" }),
    publicProvider()
  ]
);
const { connectors } = getDefaultWallets({
  appName: 'My RainbowKit App',
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
      <div>Hello</div>
      <ConnectButton label="Connect " />
    </ChakraProvider>

   </RainbowKitProvider>
    </WagmiConfig>
    

    </>
    
  )
}
